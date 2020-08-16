import * as React from "react";
import * as ReactDOM from "react-dom";
const queryString = require('query-string');

import App from "./App";

import "./index.scss";
import { Spinner } from "@blueprintjs/core";

const query = queryString.parse(location.search);

const debug = query.debug;
const monitorHost = query.monitor_host || "http://localhost:8686";

let root = document.getElementById("root");
ReactDOM.render(
    <Spinner size={ Spinner.SIZE_LARGE } />,
    root
);

fetch(`${monitorHost}/monitor/meta`, {
    mode: "cors",
}).then(res => {
    return res.json();
}).then((meta) => {
    ReactDOM.render(
        <App debug={ debug } monitorHost={ monitorHost } monitorTitle={ meta.title } chartFormats={ meta.chart_formats } />,
        document.getElementById("root"),
    );
});
