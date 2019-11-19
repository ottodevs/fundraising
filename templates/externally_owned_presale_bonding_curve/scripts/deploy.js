const deployTemplate = require('../lib/deploy-template')

const TEMPLATE_NAME = 'externally-owned-presale-bonding-curve-template'
const CONTRACT_NAME = 'EOPBCTemplate'

const APPS = [
  { name: 'agent', contractName: 'Agent' },
  { name: 'token-manager', contractName: 'TokenManager' },
  { name: 'bancor-formula', contractName: 'BancorFormula' },
  { name: 'batched-bancor-market-maker', contractName: 'BatchedBancorMarketMaker' },
  { name: 'tap', contractName: 'TapDisabled' },
  { name: 'aragon-fundraising', contractName: 'AragonFundraisingController' },
  { name: 'presale', contractName: 'BalanceRedirectPresale' },
]

module.exports = callback => {
  deployTemplate(web3, artifacts, TEMPLATE_NAME, CONTRACT_NAME, APPS)
    .then(template => {
      console.log(template.address)
      callback()
    })
    .catch(callback)
}
