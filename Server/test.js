const os = require('os');

function getWifiIP() {
    const networkInterfaces = os.networkInterfaces();
    for (const interfaceName in networkInterfaces) {
        if (interfaceName.toLowerCase().includes('wi-fi') || interfaceName.toLowerCase().includes('wlan') || interfaceName.toLowerCase().includes('en')) {
            const networkInterface = networkInterfaces[interfaceName];
            for (const interfaceInfo of networkInterface) {
                if (interfaceInfo.family === 'IPv4' && !interfaceInfo.internal) {
                    return interfaceInfo.address;
                }
            }
        }
    }
    return 'Không tìm thấy địa chỉ IP Wi-Fi.';
}

console.log('Địa chỉ IP Wi-Fi:', getWifiIP());
