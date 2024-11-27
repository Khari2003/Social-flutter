import React, { Component } from "react";
import { StyleSheet, View } from "react-native";
import Mapbox, {MapView} from "@rnmapbox/maps";

Mapbox.setAccessToken("sk.eyJ1Ijoibmd1eWVua2hhaTIwMDMiLCJhIjoiY20zeWU3MWprMW41cjJxcXR0MnV1Mzd3cyJ9.T61Pb9TzGssFblB38wLURA");

const styles = StyleSheet.create({
  page: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#F5FCFF"
  },
  container: {
    height: 300,
    width: 300,
    backgroundColor: "tomato"
  },
  map: {
    flex: 1
  }
});

export default class App extends Component {
  componentDidMount() {
    Mapbox.setTelemetryEnabled(false);
  }

  render() {
    return (
      <View style={styles.page}>
        <View style={styles.container}>
          <MapView style={styles.map} />
        </View>
      </View>
    );
  }
}