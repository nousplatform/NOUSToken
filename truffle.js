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
            gas:   4704624,
            //from: "0x26E196dbdE4d6cFA212fd5447B159Ad86cdB295f",
            from: "0x719a22E179bb49a4596eFe3BD6F735b8f3b00AF1",
        }
    },
    rpc: {
        host: 'localhost',
        post:8080
    }
};
