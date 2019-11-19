const Template = artifacts.require('ANJTemplate')

const { getEventArgument } = require('@aragon/test-helpers/events')

const DAYS = 24 * 3600
const WEEKS = 7 * DAYS
const PPM = 1e6

const MEMBERS = ['0xb4124cEB3451635DAcedd11767f004d8a28c6eE7']

const TOKEN_NAME = 'Aragon Network Governance'
const TOKEN_SYMBOL = 'ANG'

const VOTE_DURATION = WEEKS
const SUPPORT_REQUIRED = 50e16
const MIN_ACCEPTANCE_QUORUM = 50e16
const VOTING_SETTINGS = [SUPPORT_REQUIRED, MIN_ACCEPTANCE_QUORUM, VOTE_DURATION]

const PRESALE_PERIOD = 14 * DAYS
const PRESALE_EXCHANGE_RATE = 2 * PPM

const VIRTUAL_SUPPLIES = [Math.pow(10, 23), Math.pow(10, 23)]
const VIRTUAL_BALANCES = [Math.pow(10, 22), Math.pow(10, 22)]
const RESERVE_RATIOS = [100000, 10000]
const RATE = 5 * Math.pow(10, 15)
const FLOOR = Math.pow(10, 21)
const SLIPPAGES = [2 * Math.pow(10, 17), Math.pow(10, 18)]
const BATCH_BLOCKS = 1

const ID = 'fundraising' + Math.random()

module.exports = async callback => {
  try {
    const template = await Template.at(process.argv[6])

    const receipt = await template.prepareInstance(TOKEN_NAME, TOKEN_SYMBOL, MEMBERS, VOTING_SETTINGS, 0, { gasPrice: 60000000001 })
    await template.installShareApps(TOKEN_NAME, TOKEN_SYMBOL, VOTING_SETTINGS, { gasPrice: 60000000001 })
    await template.installFundraisingApps(
      PRESALE_GOAL,
      PRESALE_PERIOD,
      PRESALE_EXCHANGE_RATE,
      VESTING_CLIFF_PERIOD,
      VESTING_COMPLETE_PERIOD,
      PERCENT_SUPPLY_OFFERED,
      PERCENT_FUNDING_FOR_BENEFICIARY,
      0,
      BATCH_BLOCKS,
      MAXIMUM_TAP_RATE_INCREASE_PCT,
      MAXIMUM_TAP_FLOOR_DECREASE_PCT,
      { gasPrice: 60000000001 }
    )
    await template.finalizeInstance(ID, VIRTUAL_SUPPLIES, VIRTUAL_BALANCES, SLIPPAGES, RATE, FLOOR, { gasPrice: 60000000001 })
    const dao = getEventArgument(receipt, 'DeployDao', 'dao')
    console.log('DAO deployed at ' + dao)
  } catch (err) {
    console.log(err)
  }

  callback()
}
