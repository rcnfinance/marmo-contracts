module.exports = {
    networks: {
        development: {
            host: '127.0.0.1',
            port: 8545,
            // eslint-disable-next-line camelcase
            network_id: '*',
        },
    },
    compilers: {
        solc: {
            version: '0.5.5',
            docker: false,
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
                evmVersion: 'constantinople',
            },
        },
    },
};
