import * as React from "react";
import * as ReactDOM from "react-dom";
const queryString = require('query-string');

import App from "./App";

import "./index.scss";

const query = queryString.parse(location.search);

const debug = query.debug;
const monitorHost = query.monitor_host || "http://localhost:8686";

let root = document.getElementById("root");

ReactDOM.render(
    <App debug={ debug } monitorHost={ monitorHost } />,
    document.getElementById("root"),
);
