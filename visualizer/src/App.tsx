import { useState, useEffect } from 'react';
import queryString from 'query-string';

import { Card, Spinner, SpinnerSize } from "@blueprintjs/core";

import Collector from './Collector';

const INTERVAL = 5000;

function App(props: { monitorHost: string, debug: boolean }) {
    const [displayDebug] = useState(props.debug ? "block" : "none");
    const [intervalId, setIntervalId] = useState(0);
    const [log, setLog] = useState("");

    const [metaData, setMetaData] = useState({} as { [key: string]: CollectorMetaData });
    const [data, setData] = useState({} as { [key: string]: CollectorData });
    const [dataRevision, setDataRevision] = useState(0);

    const [monitorOptions, setMonitorOptions] = useState({} as MonitorOptions);

    useEffect(() => {
        if (intervalId != 0) {
            return;
        }
        fetch(`${props.monitorHost}/monitor/meta`, {
            mode: "cors",
        }).then(res => {
            return res.json();
        }).then((metaData_) => {
            let metaData = metaData_ as { [key: string]: CollectorMetaData };
            Object.keys(metaData).forEach((collectorName: string) => {
                data[collectorName] = {};
                monitorOptions[collectorName] = metaData[collectorName].options;
            });
            setMetaData(metaData);
            setMonitorOptions(monitorOptions);

            let newIntervalId = window.setInterval(()=>{
                let queryOptions = {} as { [name: string]: string };
                Object.keys(monitorOptions).forEach((collectorName) => {
                    queryOptions[collectorName] = JSON.stringify({ enabled: monitorOptions[collectorName].enabled });
                });
                let query = queryString.stringify(queryOptions);
                fetch(`${props.monitorHost}/monitor?${query}`, {
                    mode: "cors",
                }).then(res => {
                    return res.json();
                }).then((monitorData_) => {
                    let monitorData = monitorData_ as MonitorData;
                    Object.keys(monitorData).forEach((pid) => {
                        let procMonitorData = monitorData[pid];
                        Object.keys(procMonitorData).forEach((chartName) => {
                            let monitorChartData = procMonitorData[chartName];
                            let chartData = data[chartName];
                            let procChartData: { [p: string]: ((number | Date)[] | (number | Date)) } = chartData[pid] = chartData[pid] || {};
                            procChartData["date"] = procChartData["date"] || [];
                            (procChartData["date"] as (number | Date)[]).push(new Date(monitorChartData.ts * 1000));

                            let collectorDataFormats: DataFormat[] = metaData[chartName].data;
                            Object.keys(monitorChartData.data).forEach((metricsName: string) => {
                                // @ts-ignore
                                let metricsFormat = collectorDataFormats[metricsName];
                                if (metricsFormat.mode == "overwrite") {
                                    procChartData[metricsName] = monitorChartData.data[metricsName];
                                } else {
                                    procChartData[metricsName] = procChartData[metricsName] || [];
                                    (procChartData[metricsName] as (number | Date)[]).push(monitorChartData.data[metricsName]);
                                }
                            });
                        });
                    });

                    setData(data);
                    setDataRevision(new Date().getTime());
                    if (props.debug) {
                        setLog(JSON.stringify(data));
                    }
                });
            }, INTERVAL);
            setIntervalId(newIntervalId);
        });

        return () => {
            if (intervalId != 0) {
                clearTimeout(intervalId);
                setIntervalId(0);
            }
        };
    });

    if (!metaData || Object.keys(metaData).length == 0) {
        return <Spinner size={ SpinnerSize.LARGE } />;
    }
    let collectors = Object.keys(metaData).map((collectorName, i) => {
        let collectorOptions = monitorOptions[collectorName];
        let collectorData = data[collectorName];
        return (
            <Collector key={`app-collector-${i}`} metaData={metaData[collectorName]} data={collectorData} dataRevision={dataRevision} options={collectorOptions} />
        );
    });
    return (
        <div id="app">
            { collectors }

            <Card style={ {display: displayDebug } }>
                <h3>Debug log</h3>
                <div>{log}</div>
            </Card>
        </div>
    );
}

export default App;
