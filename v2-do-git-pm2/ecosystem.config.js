module.exports = {
    apps: [
        {
            name: "web-app",
            script: "server.js",
            // "max" uses all available CPU cores (Cluster Mode)
            instances: "max",
            // "cluster" enables zero-downtime reloads
            exec_mode: "cluster",
            env: {
                NODE_ENV: "production",
                PORT: 8000,
            },
        },
    ],
};
