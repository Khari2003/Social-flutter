import { registerRootComponent } from 'expo';

import App from './App';

import MapboxGL from '@rnmapbox/maps';
MapboxGL.setAccessToken('sk.eyJ1Ijoibmd1eWVua2hhaTIwMDMiLCJhIjoiY20zeWU3MWprMW41cjJxcXR0MnV1Mzd3cyJ9.T61Pb9TzGssFblB38wLURA');

// registerRootComponent calls AppRegistry.registerComponent('main', () => App);
// It also ensures that whether you load the app in Expo Go or in a native build,
// the environment is set up appropriately
registerRootComponent(App);
