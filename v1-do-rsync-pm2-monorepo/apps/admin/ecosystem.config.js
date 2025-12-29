module.exports = {
    apps: [
        {
            name: "admin-app", // Unique Name - must be different for each app
            script: "server.js",
            // Admin panels often don't need cluster mode
            instances: "1",
            exec_mode: "fork",
            env: {
                NODE_ENV: "production",
                PORT: 3001, // Unique Port - must match Nginx config and be different for each app
            },
        },
    ],
};

