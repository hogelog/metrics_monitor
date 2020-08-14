import * as React from "react";
import * as ReactDOM from "react-dom";

import App from "./App";

import "./index.scss";
import { Icon, Classes, Spinner } from "@blueprintjs/core";

const debug = location.search.indexOf("debug=1") >= 0;

let root = document.getElementById("root");
ReactDOM.render(
    <Spinner size={ Spinner.SIZE_LARGE } />,
    root
);

fetch("http://localhost:8686/metrics/meta", {
    mode: "cors",
}).then(res => {
    return res.json();
}).then((meta) => {
    ReactDOM.render(
        <App debug={ debug } monitorTitle={ meta.title } chartFormats={ meta.chart_formats } />,
        document.getElementById("root"),
    );
});
