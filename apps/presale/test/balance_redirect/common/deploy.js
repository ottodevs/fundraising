const { prepareDefaultSetup } = require('../../common/deploy')

const Presale = artifacts.require('BalanceRedirectPresaleMock.sol')

const {
  PRESALE_PERIOD,
  PRESALE_EXCHANGE_RATE,
  RESERVE_RATIOS,
} = require('@ablack/fundraising-shared-test-helpers/constants')

const PRESALE_STATE = {
  PENDING: 0,
  FUNDING: 1,
  FINISHED: 2,
  CLOSED: 3,
}

const deploy = {
  PRESALE_STATE,

  initializePresale: async (test, params) => {
    const paramsArr = [
      params.fundraising,
      params.tokenManager,
      params.reserve,
      params.beneficiary,
      params.contributionToken,
      params.presalePeriod,
      params.presaleExchangeRate,
      params.futureReserveRatio,
      params.mintingForBeneficiaryPct,
      params.startDate,
    ]
    return test.presale.initialize(...paramsArr)
  },

  prepareDefaultSetup: async (test, appManager, presaleArtifact = Presale) => {
    await prepareDefaultSetup(test, appManager, presaleArtifact)
  },

  defaultDeployParams: (test, beneficiary) => {
    return {
      fundraising: test.fundraising.address,
      tokenManager: test.tokenManager.address,
      reserve: test.reserve.address,
      beneficiary,
      contributionToken: test.contributionToken.address,
      presalePeriod: PRESALE_PERIOD,
      presaleExchangeRate: PRESALE_EXCHANGE_RATE,
      futureReserveRatio: RESERVE_RATIOS[0],
      mintingForBeneficiaryPct: 0,
      startDate: 0,
    }
  },

  deployDefaultSetup: async (test, appManager) => {
    await deploy.prepareDefaultSetup(test, appManager, Presale)
    return await deploy.initializePresale(test, deploy.defaultDeployParams(test, appManager))
  },
}

module.exports = deploy
