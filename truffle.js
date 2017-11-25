module.exports = {
  networks: {
    test: {
      host: 'localhost',
      port: 8545,
      network_id: '*', // Match any network id
      // gas:400000000000,
      gasPrice : 1,
      gas : 4000000000
    }
  }
}

// 40000000000000000000000
// 100000000000000000000