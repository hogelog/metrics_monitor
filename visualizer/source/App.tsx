import * as React from 'react';
import { useState, useEffect } from 'react';

import { Card, Classes } from "@blueprintjs/core";

import Plot from 'react-plotly.js';

const INTERVAL = 5000;

function App(props: { monitorHost: string, monitorTitle: string, chartFormats: any[]; debug: any; }) {
    const initData: { [key: string]: (number | Date)[] } = { date: [] as Date[] };
    props.chartFormats.forEach((format) => {
        initData[format.key] = [];
    });
    const [intervalId, setIntervalId] = useState(0);
    const [data, setData] = useState(initData);
    const [log, setLog] = useState("");
    const [displayDebug] = useState(props.debug ? "block" : "none");
    const [dataRevision, setDataRevision] = useState(0);

    useEffect(() => {
        if (intervalId != 0) {
            return;
        }
        let newIntervalId = window.setInterval(()=>{
            fetch(`${props.monitorHost}/monitor`, {
                mode: "cors",
            }).then(res => {
                return res.json();
            }).then((metrics) => {
                data.date.push(new Date(metrics.ts * 1000));
                props.chartFormats.forEach((format) => {
                    data[format.key].push( metrics.data[format.key]);
                });

                setDataRevision(metrics.ts);
                if (props.debug) {
                    setLog(JSON.stringify(data));
                }
            });
        }, INTERVAL);
        setIntervalId(newIntervalId);

        return () => {
            if (intervalId != 0) {
                clearTimeout(intervalId);
                setIntervalId(0);
            }
        };
    });

    let charts: Plot[] = [];
    props.chartFormats.forEach((format) => {
        charts.push(
            <Plot
              key={ format["key"]},
              data={[{
                  x: data["date"],
                  y: data[format["key"]],
                  type: "scatter",
                  mode: "lines+markers",
                  fill: 'tozeroy',
              }]}
              layout={ {
                  width: 400,
                  height: 300,
                  title: format["title"],
                  yaxis: {
                      zeroline: true,
                  },
                  datarevision: dataRevision,
              } }
            />
        );
    });

    return (
        <div id="app">
            <h2 className={ Classes.HEADING}>{props.monitorTitle}</h2>
            { charts }

            <Card style={ {display: displayDebug } }>
                <h3>Debug log</h3>
                <div>{log}</div>
            </Card>
        </div>
    );
}

export default App;
