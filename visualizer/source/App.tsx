import * as React from 'react';
import { useState, useEffect } from 'react';

import { Card, Classes, Spinner } from "@blueprintjs/core";

import Plot from 'react-plotly.js';

const INTERVAL = 5000;

function App(props: { monitorHost: string; debug: any; }) {
    const initData: { [key: string]: (number | Date)[] } = { date: [] as Date[] };
    const [intervalId, setIntervalId] = useState(0);
    const [data, setData] = useState(initData);
    const [log, setLog] = useState("");
    const [displayDebug] = useState(props.debug ? "block" : "none");
    const [dataRevision, setDataRevision] = useState(0);

    const [monitorTitle, setMonitorTitle] = useState("");
    const [chartFormats, setChartFormats] = useState([] as { key: string, title: string, type: string}[]);

    const plot = (format: { key: string, title: string, type: string }) => {
        let fill : "tozeroy" | "none";
        switch (format.type) {
            case "area":
                fill = "tozeroy";
                break;
            default:
                fill = "none";
        }
        return (
            <Plot
                key={format.key}
                data={[{
                    x: data["date"],
                    y: data[format["key"]],
                    type: "scatter",
                    mode: "lines+markers",
                    fill: fill,
                }]}
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
    };

    useEffect(() => {
        if (intervalId != 0) {
            return;
        }
        fetch(`${props.monitorHost}/monitor/meta`, {
            mode: "cors",
        }).then(res => {
            return res.json();
        }).then((meta) => {
            setMonitorTitle(meta.title);
            setChartFormats(meta.chart_formats);
            chartFormats.forEach((format) => {
                data[format.key] = [];
            });

            let newIntervalId = window.setInterval(()=>{
                fetch(`${props.monitorHost}/monitor`, {
                    mode: "cors",
                }).then(res => {
                    return res.json();
                }).then((metrics) => {
                    data.date.push(new Date(metrics.ts * 1000));
                    chartFormats.forEach((format) => {
                        data[format.key].push( metrics.data[format.key]);
                    });

                    setDataRevision(metrics.ts);
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

    if (chartFormats.length == 0) {
        return <Spinner size={ Spinner.SIZE_LARGE } />;
    } 
    return (
        <div id="app">
            <h2 className={ Classes.HEADING}>{monitorTitle}</h2>
            { chartFormats.map((format) => plot(format)) }

            <Card style={ {display: displayDebug } }>
                <h3>Debug log</h3>
                <div>{log}</div>
            </Card>
        </div>
    );
}

export default App;

