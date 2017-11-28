module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            gas:   4700000,
            //from: "0xc2Ddda15f8deB297EB4DE39B82ae0750dF693253",
        },
        prod: {
            host: "localhost",
            port: 8545,
            network_id: "*", // Match any network id
            gas:   4700000,
            from: "0xc2Ddda15f8deB297EB4DE39B82ae0750dF693253",
        },
        ropsten_out_2:  {
            network_id: 3,
            host: "82.117.232.61",
            port:  8546,
            gas:   4700000,
            //from: "0xad4016f585da476073c7d53a5e53d9ec6c735204",
            from: "0x719a22e179bb49a4596efe3bd6f735b8f3b00af1",
        },
        ropsten_local:  {
            network_id: 3,
            host: "192.168.88.11",
            port:  8545,
            gas:   4700000,
            from: "0x719a22e179bb49a4596efe3bd6f735b8f3b00af1",
        }
    },
    rpc: {
        host: 'localhost',
        post:8080
    }
};
