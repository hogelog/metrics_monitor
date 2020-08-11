import * as React from "react";
import * as ReactDOM from "react-dom";

import App from "./App";

const debug = location.search.indexOf("debug=1") >= 0;

fetch("http://localhost:8686/metrics/meta", {
    mode: "cors",
}).then(res => {
    return res.json();
}).then((meta) => {
    ReactDOM.render(
        <App debug={ debug } chartFormats={ meta.chart_formats } />,
        document.getElementById("root"),
    );
});
