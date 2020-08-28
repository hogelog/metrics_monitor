import * as React from "react";
import * as ReactDOM from "react-dom";
import * as queryString from 'query-string';

import App from "./App";

import "./index.scss";

const query = queryString.parse(location.search);

const debug = !!query.debug;
const monitorHost = (query.monitor_host || "http://localhost:8686") as string;

let root = document.getElementById("root");

ReactDOM.render(
    <App monitorHost={monitorHost} debug={debug} />,
    document.getElementById("root"),
);
