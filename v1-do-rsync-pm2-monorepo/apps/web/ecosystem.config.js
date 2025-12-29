module.exports = {
    apps: [
        {
            name: "web-app", // Unique Name - must be different for each app
            script: "server.js",
            // "max" uses all available CPU cores (Cluster Mode)
            instances: "max",
            // "cluster" enables zero-downtime reloads
            exec_mode: "cluster",
            env: {
                NODE_ENV: "production",
                PORT: 3000, // Unique Port - must match Nginx config and be different for each app
            },
        },
    ],
};

