import * as React from 'react';
import { useState, useEffect } from 'react';

import { Card, Classes, Spinner, Tab } from "@blueprintjs/core";
import { Table, Column, Cell } from "@blueprintjs/table";

import Plot from 'react-plotly.js';

const INTERVAL = 5000;

interface ChartData {
    [pid: string]: {
        [key: string]: (number | Date)[]
    }
}

interface ChartMetaData {
    title: string;
    monitors: MonitorFormat[];
}

interface MonitorFormat {
    key: string;
    title: string;
    type: "chart" | "table";
    mode: "line" | "area";
}

interface MonitorChartData {
    ts: number;
    data: {
        [name: string]: number;
    };
}

interface MonitorData {
    [pid: string]: {
        [name: string]: MonitorChartData;
    }
}

function formatChartData(format: MonitorFormat, chartData: ChartData) {
    let fill : "tozeroy" | "none";
    switch (format.mode) {
        case "area":
            fill = "tozeroy";
            break;
        default:
            fill = "none";
    }

    let data = [] as Plotly.Data[];
    Object.keys(chartData).forEach((pid) => {
        let procData = chartData[pid];
        data.push({
            name: pid,
            x: procData["date"],
            y: procData[format.key],
            type: "scatter",
            mode: "lines+markers",
            fill: fill,
        });
    });
    return data;
}

function tableCellRenderer(key: string, collectorData: ChartData) {
    return (rowIndex: number) => {
        let pids = Object.keys(collectorData);
        let pid = pids[rowIndex];
        let targetData = collectorData[pid][key];
        return <Cell>{ targetData[targetData.length - 1] }</Cell>;
    };
}

function drawTable(collectorName: string, format: MonitorFormat, data: { [key: string]: ChartData }) {
    let keys = format.key.split(",");
    let collectorData = data[collectorName];
    let pids = Object.keys(collectorData);

    return (
        <Table numRows={Object.keys(collectorData).length}>
            { keys.map((key) => <Column name={key} cellRenderer={tableCellRenderer(key, collectorData)} />) }
        </Table>
    );
}

function drawChart(collectorName: string, format: MonitorFormat, data: { [key: string]: ChartData }, dataRevision: number) {
    return (
        <Plot
            key={ format.key }
            data={ formatChartData(format, data[collectorName]) }
            layout={{
                width: 400,
                height: 300,
                title: format["title"],
                yaxis: {
                    zeroline: true,
                },
                datarevision: dataRevision,
            }}
        />
    );
}

function drawMonitor(collectorName: string, format: MonitorFormat, data: { [key: string]: ChartData }, dataRevision: number) {
    switch (format.type) {
        case "table":
            return drawTable(collectorName, format, data);
        case "chart":
            return drawChart(collectorName, format, data, dataRevision);
    }
}

function drawCollector(collectorName: string, chartMetaData: ChartMetaData, data: { [key: string]: ChartData }, dataRevision: number) {
    return (
        <div>
            <h2 className={ Classes.HEADING}>{chartMetaData.title}</h2>
            { chartMetaData.monitors.map((format) => drawMonitor(collectorName, format, data, dataRevision)) }
        </div>
    );
}

function App(props: { monitorHost: string; debug: any; }) {
    const [displayDebug] = useState(props.debug ? "block" : "none");
    const [intervalId, setIntervalId] = useState(0);
    const [log, setLog] = useState("");

    const [metaData, setMetaData] = useState({} as { [key: string]: ChartMetaData });
    const [data, setData] = useState({} as { [key: string]: ChartData });
    const [dataRevision, setDataRevision] = useState(0);

    useEffect(() => {
        if (intervalId != 0) {
            return;
        }
        fetch(`${props.monitorHost}/monitor/meta`, {
            mode: "cors",
        }).then(res => {
            return res.json();
        }).then((metaData_) => {
            let metaData = metaData_ as { [key: string]: ChartMetaData };
            Object.keys(metaData).forEach((chartName: string) => {
                data[chartName] = {};
            });
            setMetaData(metaData);

            let newIntervalId = window.setInterval(()=>{
                fetch(`${props.monitorHost}/monitor`, {
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
                            let procChartData = chartData[pid] = chartData[pid] || {};
                            console.log([chartName, chartData, procChartData]);
                            procChartData["date"] = procChartData["date"] || [];
                            procChartData["date"].push(new Date(monitorChartData.ts * 1000));

                            Object.keys(monitorChartData.data).forEach((metricsName: string) => {
                                procChartData[metricsName] = procChartData[metricsName] || [];
                                procChartData[metricsName].push(monitorChartData.data[metricsName]);
                            });
                        });
                    });
                    console.log(data);

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
        return <Spinner size={ Spinner.SIZE_LARGE } />;
    } 
    return (
        <div id="app">
            { Object.keys(metaData).map((collectorName) => drawCollector(collectorName, metaData[collectorName], data, dataRevision)) }

            <Card style={ {display: displayDebug } }>
                <h3>Debug log</h3>
                <div>{log}</div>
            </Card>
        </div>
    );
}

export default App;
