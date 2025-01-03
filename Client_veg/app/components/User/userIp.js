import React, { useEffect, useState } from 'react';
import { View, Text } from 'react-native';
import { NetworkInfo } from 'react-native-network-info';

const userIp = () => {
  const [ipAddress, setIpAddress] = useState('');
  const [gatewayIp, setGatewayIp] = useState('');
  const [ssid, setSsid] = useState('');

  useEffect(() => {
    // Lấy địa chỉ IP
    NetworkInfo.getIPAddress().then(ip => setIpAddress(ip));

    // Lấy địa chỉ IP của Gateway
    NetworkInfo.getGatewayIPAddress().then(gateway => setGatewayIp(gateway));

    // Lấy SSID của mạng Wi-Fi
    NetworkInfo.getSSID().then(networkSsid => setSsid(networkSsid));
  }, []);

  return {ipAddress, gatewayIp,ssid}
};

export default userIp;
