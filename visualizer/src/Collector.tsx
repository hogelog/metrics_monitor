import * as React from 'react';
import { useState, useEffect } from 'react';

import { Classes, Switch } from "@blueprintjs/core";
import { Table, Column, Cell } from "@blueprintjs/table";

import Plot from 'react-plotly.js';

function TextMonitor(props: { format: MonitorFormat, data: CollectorData}) {
    let pids = Object.keys(props.data);

    let texts = [] as any;
    pids.forEach((pid : string) => {
        let targetData = props.data[pid][props.format.key];
        texts.push(
            <div>
                <h4>{ pid }</h4>
                <pre className={Classes.CODE_BLOCK}>
                    { targetData }
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
            return <Cell>{ targetData[targetData.length - 1] }</Cell>;
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

function Collector(props: { metaData: CollectorMetaData; data: CollectorData; dataRevision: number, options: CollectorOptions;}) {
  const [enabled, setEnabled] = useState(props.options.enabled);
  
  let onSwitchChange = (_: React.FormEvent<HTMLInputElement>) => {
    props.options.enabled = !props.options.enabled;
    setEnabled(props.options.enabled);
  };
  return (
      <div>
          <h2 className={ Classes.HEADING }>
              {props.metaData.title}
              <Switch checked={ enabled } onChange={ onSwitchChange } />
          </h2>
          { props.metaData.monitors.map((format, i) => <Monitor key={`collector-monitor-${i}`} format={format} data={props.data} dataRevision={props.dataRevision} />) }
      </div>
  );
}

export default Collector;
