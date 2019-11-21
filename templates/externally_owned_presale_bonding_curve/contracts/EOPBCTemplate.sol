pragma solidity 0.4.24;

import "@aragon/os/contracts/common/EtherTokenConstant.sol";
import "@aragon/os/contracts/lib/token/ERC20.sol";
import "@aragon/templates-shared/contracts/BaseTemplate.sol";
import "@aragon/apps-agent/contracts/Agent.sol";
import "@ablack/fundraising-bancor-formula/contracts/BancorFormula.sol";
import {AragonFundraisingController as Controller} from "@ablack/fundraising-aragon-fundraising/contracts/AragonFundraisingController.sol";
import {BatchedBancorMarketMaker as MarketMaker} from "@ablack/fundraising-batched-bancor-market-maker/contracts/BatchedBancorMarketMaker.sol";
import "@ablack/fundraising-presale/contracts/IPresale.sol";
import {BalanceRedirectPresale as Presale} from "@ablack/fundraising-presale/contracts/BalanceRedirectPresale.sol";
import {TapDisabled as Tap} from "@ablack/fundraising-tap/contracts/TapDisabled.sol";


/**
 * This template is intended to be used for ANJ Presale and bonding curve deployment.
 * But it can be re-used by any project needing only a bonding curve along with a previous presale at a fixed price.
 * It doesn't have Aragon core apps, it's externally owned.
 * Besides there is no tap mechanism, as it's not intended for fundraising, but just for bonding tokens.
*/
contract EOPBCTemplate is EtherTokenConstant, BaseTemplate {
    string    private constant ERROR_BAD_SETTINGS     = "EOPBC_TEMPLATE_BAD_SETTINGS";
    string    private constant ERROR_MISSING_CACHE    = "EOPBC_TEMPLATE_MISSING_CACHE";

    bool      private constant BONDED_TOKEN_TRANSFERABLE     = true;
    uint8     private constant BONDED_TOKEN_DECIMALS   = uint8(18);
    uint256   private constant BONDED_TOKEN_MAX_PER_ACCOUNT  = uint256(0);

    uint256   private constant BUY_FEE_PCT            = 0;
    uint256   private constant SELL_FEE_PCT           = 0;

    bytes32   private constant BANCOR_FORMULA_ID      = 0xd71dde5e4bea1928026c1779bde7ed27bd7ef3d0ce9802e4117631eb6fa4ed7d;
    bytes32   private constant PRESALE_ID             = 0x5de9bbdeaf6584c220c7b7f1922383bcd8bbcd4b48832080afd9d5ebf9a04df5;
    bytes32   private constant MARKET_MAKER_ID        = 0xc2bb88ab974c474221f15f691ed9da38be2f5d37364180cec05403c656981bf0;
    bytes32   private constant ARAGON_FUNDRAISING_ID  = 0x668ac370eed7e5861234d1c0a1e512686f53594fcb887e5bcecc35675a4becac;

    struct Cache {
        address reserve;
        address presale;
        address marketMaker;
        address tap;
        address controller;
        address bondedTokenManager;
    }

    mapping (address => Cache) private cache;

    constructor(
        DAOFactory              _daoFactory,
        ENS                     _ens,
        MiniMeTokenFactory      _miniMeFactory,
        IFIFSResolvingRegistrar _aragonID
    )
        BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
        public
    {
        _ensureAragonIdIsValid(_aragonID);
        _ensureMiniMeFactoryIsValid(_miniMeFactory);
    }

    /***** external functions *****/

    function installFundraisingApps(
        address       _owner,
        string        _id,
        ERC20         _collateralToken,
        MiniMeToken   _bondedToken,
        uint64        _period,
        uint256       _exchangeRate,
        uint64        _openDate,
        uint256       _reserveRatio,
        uint256       _batchBlocks,
        uint256       _slippage
    )
        external
    {
        require(_owner != address(0), ERROR_BAD_SETTINGS);
        require(isContract(_collateralToken), ERROR_BAD_SETTINGS);
        require(isContract(_bondedToken), ERROR_BAD_SETTINGS);
        require(bytes(_id).length > 0, ERROR_BAD_SETTINGS);

        // deploy DAO
        (Kernel dao, ACL acl) = _createDAO();

        // install fundraising apps
        _proxifyFundraisingApps(dao, _bondedToken);

        _initializePresale(
            _owner,
            _collateralToken,
            _period,
            _exchangeRate,
            _reserveRatio,
            _openDate
        );
        _initializeMarketMaker(_owner, _batchBlocks);
        _initializeController();

        // setup fundraising apps permissions
        _setupFundraisingPermissions(acl, _owner);

        // setup collateral
        _setupCollateral(acl, _owner, _collateralToken, _reserveRatio, _slippage);
        // clear DAO permissions
        _transferRootPermissionsFromTemplateAndFinalizeDAO(dao, _owner, _owner);
        // register id
        _registerID(_id, address(dao));
        // clear cache
        _clearCache();
    }

    /***** internal apps installation functions *****/

    function _proxifyFundraisingApps(Kernel _dao, MiniMeToken _bondedToken) internal {
        Agent reserve = _installNonDefaultAgentApp(_dao);
        Presale presale = Presale(_registerApp(_dao, PRESALE_ID));
        MarketMaker marketMaker = MarketMaker(_registerApp(_dao, MARKET_MAKER_ID));
        Tap tap = new Tap();
        Controller controller = Controller(_registerApp(_dao, ARAGON_FUNDRAISING_ID));
        // bonded token manager
        TokenManager bondedTokenManager = _installTokenManagerApp(_dao, _bondedToken, BONDED_TOKEN_TRANSFERABLE, BONDED_TOKEN_MAX_PER_ACCOUNT);

        _cacheFundraisingApps(reserve, presale, marketMaker, tap, controller, bondedTokenManager);
    }

    /***** internal apps initialization functions *****/

    function _initializePresale(
        address _beneficiary,
        ERC20   _collateralToken,
        uint64  _period,
        uint256 _exchangeRate,
        uint256 _futureReserveRatio,
        uint64  _openDate
    )
        internal
    {
        (Agent reserve, Presale presale,,, Controller controller, TokenManager tokenManager) = _fundraisingAppsCache();

        presale.initialize(
            controller,
            tokenManager,
            reserve,
            _beneficiary,
            _collateralToken,
            _period,
            _exchangeRate,
            _futureReserveRatio,
            _openDate
        );
    }

    function _initializeMarketMaker(address _beneficiary, uint256 _batchBlocks) internal {
        IBancorFormula bancorFormula = IBancorFormula(_latestVersionAppBase(BANCOR_FORMULA_ID));

        (Agent reserve,, MarketMaker marketMaker,, Controller controller, TokenManager tokenManager) = _fundraisingAppsCache();

        marketMaker.initialize(controller, tokenManager, bancorFormula, reserve, _beneficiary, _batchBlocks, BUY_FEE_PCT, SELL_FEE_PCT);
    }

    function _initializeController() internal {
        (Agent reserve, IPresale presale, MarketMaker marketMaker, Tap tap, Controller controller,) = _fundraisingAppsCache();
        address[] memory toReset = new address[](0);
        controller.initialize(presale, marketMaker, reserve, tap, toReset);
    }

    /***** internal setup functions *****/

    function _setupCollateral(
        ACL        _acl,
        address    _owner,
        ERC20      _collateralToken,
        uint256     _reserveRatio,
        uint256    _slippage
    )
        internal
    {
        (,,,, Controller controller,) = _fundraisingAppsCache();

        // create and grant ADD_COLLATERAL_TOKEN_ROLE to this template
        _createPermissionForTemplate(_acl, controller, controller.ADD_COLLATERAL_TOKEN_ROLE());
        // add ANT as a protected collateral [but not as a tapped token]
        controller.addCollateralToken(
            _collateralToken,
            0,
            0,
            uint32(_reserveRatio),
            _slippage,
            0,
            0
        );
        // transfer ADD_COLLATERAL_TOKEN_ROLE
        _transferPermissionFromTemplate(_acl, controller, _owner, controller.ADD_COLLATERAL_TOKEN_ROLE(), _owner);
    }

    /***** internal permissions functions *****/

    function _setupFundraisingPermissions(ACL _acl, address _owner) internal {
        address ANY_ENTITY = _acl.ANY_ENTITY();

        (Agent reserve, Presale presale, MarketMaker marketMaker,, Controller controller, TokenManager tokenManager) = _fundraisingAppsCache();

        // token manager
        address[] memory grantees = new address[](2);
        grantees[0] = address(marketMaker);
        grantees[1] = address(presale);
        _createPermissions(_acl, grantees, tokenManager, tokenManager.MINT_ROLE(), _owner);
        _acl.createPermission(marketMaker, tokenManager, tokenManager.BURN_ROLE(), _owner);
        // reserve
        _acl.createPermission(_owner, reserve, reserve.SAFE_EXECUTE_ROLE(), _owner);
        _acl.createPermission(controller, reserve, reserve.ADD_PROTECTED_TOKEN_ROLE(), _owner);
        _acl.createPermission(marketMaker, reserve, reserve.TRANSFER_ROLE(), _owner);
        // presale
        _acl.createPermission(controller, presale, presale.OPEN_ROLE(), _owner);
        _acl.createPermission(controller, presale, presale.CONTRIBUTE_ROLE(), _owner);
        // market maker
        _acl.createPermission(controller, marketMaker, marketMaker.OPEN_ROLE(), _owner);
        _acl.createPermission(controller, marketMaker, marketMaker.UPDATE_BENEFICIARY_ROLE(), _owner);
        _acl.createPermission(controller, marketMaker, marketMaker.UPDATE_FEES_ROLE(), _owner);
        _acl.createPermission(controller, marketMaker, marketMaker.ADD_COLLATERAL_TOKEN_ROLE(), _owner);
        _acl.createPermission(controller, marketMaker, marketMaker.REMOVE_COLLATERAL_TOKEN_ROLE(), _owner);
        _acl.createPermission(controller, marketMaker, marketMaker.UPDATE_COLLATERAL_TOKEN_ROLE(), _owner);
        _acl.createPermission(controller, marketMaker, marketMaker.OPEN_BUY_ORDER_ROLE(), _owner);
        _acl.createPermission(controller, marketMaker, marketMaker.OPEN_SELL_ORDER_ROLE(), _owner);
        // controller
        _acl.createPermission(_owner, controller, controller.UPDATE_BENEFICIARY_ROLE(), _owner);
        _acl.createPermission(_owner, controller, controller.UPDATE_FEES_ROLE(), _owner);
        // ADD_COLLATERAL_TOKEN_ROLE is handled later [after collaterals have been added]
        // _acl.createPermission(_owner, controller, controller.ADD_COLLATERAL_TOKEN_ROLE(), _owner);
        _acl.createPermission(_owner, controller, controller.REMOVE_COLLATERAL_TOKEN_ROLE(), _owner);
        _acl.createPermission(_owner, controller, controller.UPDATE_COLLATERAL_TOKEN_ROLE(), _owner);
        _acl.createPermission(_owner, controller, controller.OPEN_PRESALE_ROLE(), _owner);
        _acl.createPermission(presale, controller, controller.OPEN_TRADING_ROLE(), _owner);
        _acl.createPermission(ANY_ENTITY, controller, controller.CONTRIBUTE_ROLE(), _owner);
        _acl.createPermission(ANY_ENTITY, controller, controller.OPEN_BUY_ORDER_ROLE(), _owner);
        _acl.createPermission(ANY_ENTITY, controller, controller.OPEN_SELL_ORDER_ROLE(), _owner);
    }

    /***** internal cache functions *****/

    function _cacheFundraisingApps(
        Agent _reserve,
        Presale _presale,
        MarketMaker _marketMaker,
        Tap _tap,
        Controller _controller,
        TokenManager _tokenManager
    )
        internal
    {
        Cache storage c = cache[msg.sender];

        c.reserve = address(_reserve);
        c.presale = address(_presale);
        c.marketMaker = address(_marketMaker);
        c.tap = address(_tap);
        c.controller = address(_controller);
        c.bondedTokenManager = address(_tokenManager);
    }

    function _fundraisingAppsCache()
        internal
        view
        returns (Agent reserve, Presale presale, MarketMaker marketMaker, Tap tap, Controller controller, TokenManager tokenManager)
    {
        Cache storage c = cache[msg.sender];

        reserve = Agent(c.reserve);
        presale = Presale(c.presale);
        marketMaker = MarketMaker(c.marketMaker);
        tap = Tap(c.tap);
        controller = Controller(c.controller);
        tokenManager = TokenManager(c.bondedTokenManager);
    }

    function _clearCache() internal {
        Cache storage c = cache[msg.sender];

        delete c.reserve;
        delete c.presale;
        delete c.marketMaker;
        delete c.tap;
        delete c.controller;
        delete c.bondedTokenManager;
    }

    /***** internal check functions *****/

    function _ensureFundraisingAppsCache() internal view {
        Cache storage c = cache[msg.sender];
        require(
            c.reserve != address(0) &&
            c.presale != address(0) &&
            c.marketMaker != address(0) &&
            c.controller != address(0) &&
            c.bondedTokenManager != address(0),
            ERROR_MISSING_CACHE
        );
    }

    /***** internal utils functions *****/

    function _registerApp(Kernel _dao, bytes32 _appId) internal returns (address) {
        address proxy = _dao.newAppInstance(_appId, _latestVersionAppBase(_appId));

        emit InstalledApp(proxy, _appId);

        return proxy;
    }
}
