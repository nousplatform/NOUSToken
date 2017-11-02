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
            host: "192.168.88.11",
            port:  8545,
            gas:   4712388,
            //from: "0xad4016f585da476073c7d53a5e53d9ec6c735204",
            from: "0x26E196dbdE4d6cFA212fd5447B159Ad86cdB295f",
        }
    },
    rpc: {
        host: 'localhost',
        post:8080
    }
};
