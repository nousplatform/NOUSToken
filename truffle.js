module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            gas:   6993166,
            //from: "0x6e7dc7528e8a6edeb343e0df09fcd6a780f4fe20",
        },
        ropsten:  {
            network_id: 3,
            host: "82.117.232.61",
            port:  8546,
            gas:   4700000,
            //from: "0xad4016f585da476073c7d53a5e53d9ec6c735204",
            from: "0x719a22e179bb49a4596efe3bd6f735b8f3b00af1",
        }
    },
    rpc: {
        host: 'localhost',
        post:8080
    }
};
