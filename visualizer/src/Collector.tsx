import * as React from 'react';
import { useEffect, useState } from 'react';

import { Card, Classes, Switch } from "@blueprintjs/core";
import { Table, Column, Cell } from "@blueprintjs/table";

import Plot from 'react-plotly.js';

import queryString from 'query-string';

const TIMEOUT = 500;
const INTERVAL = 10_000;

function TextMonitor(props: { format: MonitorFormat, data: CollectorData}) {
    let pids = Object.keys(props.data);

    let texts = [] as any;
    pids.forEach((pid : string) => {
        let targetData = props.data[pid][props.format.key];
        texts.push(
            <div key={ pid }>
                <h4>{ pid }</h4>
                <pre className={Classes.CODE_BLOCK}>
                    { String(targetData) }
                </pre>
            </div>
        );
    });
    return (
        <div>
            <h3>{ props.format.title } </h3>
            { texts }
        </div>
    );
}

function tableCellRenderer(key: string, data: CollectorData) {
    return (rowIndex: number) => {
        let pids = Object.keys(data);
        let pid = pids[rowIndex];
        let targetData = data[pid][key];
        if (Array.isArray(targetData)) {
            return <Cell>{ String(targetData[targetData.length - 1]) }</Cell>;
        } else {
            return <Cell>{ targetData }</Cell>;
        }
    };
}

function TableMonitor(props: { format: MonitorFormat, data: CollectorData }) {
    let keys = props.format.key.split(",");
    let numRows = Object.keys(props.data).length;

    return (
        <div>
            <h3>{ props.format.title } </h3>
            <Table numRows={numRows}>
                { keys.map((key, i) => <Column key={`tablemonitor-table-${i}`} name={key} cellRenderer={tableCellRenderer(key, props.data)} />) }
            </Table>
        </div>
    );
}

function formatChartData(format: MonitorFormat, data: CollectorData) {
    let fill : "tozeroy" | "none";
    switch (format.mode) {
        case "area":
            fill = "tozeroy";
            break;
        default:
            fill = "none";
    }

    let plotData = [] as Plotly.Data[];
    Object.keys(data).forEach((pid) => {
        let procData = data[pid];
        plotData.push({
            name: pid,
            x: procData["date"],
            y: procData[format.key],
            type: "scatter",
            mode: "lines+markers",
            fill: fill,
        });
    });
    return plotData;
}

function ChartMonitor(props: { format: MonitorFormat, data: CollectorData, dataRevision: number }) {
    return (
        <Plot
            key={ props.format.key }
            data={ formatChartData(props.format, props.data) }
            layout={{
                width: 400,
                height: 300,
                title: props.format["title"],
                yaxis: {
                    zeroline: true,
                },
                datarevision: props.dataRevision,
            }}
        />
    );
}

function Monitor(props: { format: MonitorFormat, data: CollectorData, dataRevision: number }) {
    switch (props.format.type) {
        case "text":
            return <TextMonitor format={props.format} data={props.data} />
        case "table":
            return <TableMonitor format={props.format} data={props.data} />;
        case "chart":
            return <ChartMonitor format={props.format} data={props.data} dataRevision={props.dataRevision} />;
    }
}

function Collector(props: { collectorName: string; metaData: CollectorMetaData; options: CollectorOptions; monitorHost: string; debug: boolean; }) {
    const [displayDebug] = useState(props.debug ? "block" : "none");
    const [enabled, setEnabled] = useState(!!props.options.enabled);
    const [data, setData] = useState({} as CollectorData);
    const [dataRevision, setDataRevision] = useState(0);
    const [log, setLog] = useState("");
    let url = `${props.monitorHost}/monitor/${props.collectorName}`;

    useEffect(() => {
        let newIntervalId = window.setInterval(()=>{
            if (!enabled) {
                return;
            }
            fetch(url, {
                mode: "cors",
                signal: AbortSignal.timeout(TIMEOUT),
            }).then(res => {
                return res.json();
            }).then((monitorData_) => {
                let monitorData = monitorData_ as MonitorData;
                Object.keys(monitorData).forEach((pid) => {
                    monitorData[pid].forEach((monitorChartData) => {
                        if (monitorChartData.error) {
                            return;
                        }
                        let procChartData: { [p: string]: ((number | Date)[] | (number | Date)) } = data[pid] = (data[pid] || {});
                        procChartData["date"] = procChartData["date"] || [];
                        // @ts-ignore
                        (procChartData["date"] as (number | Date)[]).push(new Date(monitorChartData.ts * 1000));

                        let collectorDataFormats: DataFormat[] = props.metaData.data;
                        Object.keys(monitorChartData.data).forEach((metricsName: string) => {
                            // @ts-ignore
                            let metricsFormat = collectorDataFormats[metricsName];
                            if (metricsFormat.mode == "overwrite") {
                                // @ts-ignore
                                procChartData[metricsName] = monitorChartData.data[metricsName];
                            } else {
                                procChartData[metricsName] = procChartData[metricsName] || [];
                                // @ts-ignore
                                (procChartData[metricsName] as (number | Date)[]).push(monitorChartData.data[metricsName]);
                            }
                        });
                    });
                });

                setData(data);
                setDataRevision(new Date().getTime());
                if (props.debug) {
                    setLog(log + JSON.stringify(monitorData, null, 4));
                }
            });
        }, INTERVAL);

        return () => {
            clearTimeout(newIntervalId);
        };
    }, [enabled]);

  let onSwitchChange = (_: React.FormEvent<HTMLInputElement>) => {
    setEnabled(!enabled);
  };
  return (
      <div>
          <h2 className={ Classes.HEADING }>
              {props.metaData.title}
              <Switch checked={ enabled } onChange={ onSwitchChange } />
          </h2>
          { props.metaData.monitors.map((format, i) => <Monitor key={`collector-monitor-${i}`} format={format} data={data} dataRevision={dataRevision} />) }

          <Card style={ {display: displayDebug } }>
              <h3>Debug log</h3>
              <pre>{log}</pre>
          </Card>
      </div>
  );
}

export default Collector;
