module.exports = {
  networks: {
    test: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gasPrice : 1,
      gas : 0xfffffffffff
    },
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      gasPrice : 1,
      gas : 0xfffffffffff
    }
  }
}

// 40000000000000000000000
// 100000000000000000000
