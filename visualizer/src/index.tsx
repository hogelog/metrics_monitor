import { createRoot } from 'react-dom/client';

import queryString from 'query-string';

import App from "./App";

import "./index.scss";

const query = queryString.parse(location.search);

const debug = !!query.debug;
const monitorHost = (query.monitor_host || "http://localhost:8686") as string;

const root = createRoot(document.getElementById("root")!);
root.render(<App monitorHost={monitorHost} debug={debug} />);
