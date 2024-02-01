import { useState, useEffect } from 'react';

import { Button, Card, HotkeysProvider, Spinner, SpinnerSize } from "@blueprintjs/core";

import Collector from './Collector';

function getTimestamp() {
    const date = new Date();
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = String(date.getDate()).padStart(2, "0");
    const hour = String(date.getHours()).padStart(2, "0");
    const minute = String(date.getMinutes()).padStart(2, "0");
    const second = String(date.getSeconds()).padStart(2, "0");
    return `${year}${month}${day}-${hour}${minute}${second}`;
}

function saveSnapshot(bodyHtml: string, metaData: { [key: string]: CollectorMetaData }, monitorOptions: MonitorOptions, collectorData: { [key: string]: CollectorData }) {
    let snapshotdata: Snapshotdata = {
        metaData: metaData,
        monitorOptions: monitorOptions,
        data: collectorData,
    };
    let head = document.head.outerHTML;
    let snapshotBody = bodyHtml.replace("//SNAPSHOTDATAHERE", "snapshotdata = " + JSON.stringify(snapshotdata) + ";");
    let html = `<!DOCTYPE html>\n<html>\n${head}\n${snapshotBody}\n</html>`;

    let element = document.createElement("a");
    let file = new Blob([html], { type: "text/html" });
    element.href = URL.createObjectURL(file);
    element.download = `metricsmonitor-${getTimestamp()}.html`;
    document.body.appendChild(element);
    element.click();
    window.URL.revokeObjectURL(element.href);
    document.body.removeChild(element);
}

function App(props: { monitorHost: string; debug: boolean; bodyHtml: string; snapshotdata?: Snapshotdata }) {
    const [displayDebug] = useState(props.debug ? "block" : "none");

    let initMetaData = props.snapshotdata ? props.snapshotdata.metaData : {} as { [key: string]: CollectorMetaData };
    let initMonitorOptions = props.snapshotdata ? props.snapshotdata.monitorOptions : {} as MonitorOptions;

    const [metaData, setMetaData] = useState(initMetaData);
    const [monitorOptions, setMonitorOptions] = useState(initMonitorOptions);

    const collectorData = {} as { [key: string]: CollectorData };

    if (!props.snapshotdata) {
        useEffect(() => {
            fetch(`${props.monitorHost}/meta`, {
                mode: "cors",
            }).then(res => {
                return res.json();
            }).then((metaData_) => {
                let metaData = metaData_ as { [key: string]: CollectorMetaData };
                Object.keys(metaData).forEach((collectorName: string) => {
                    monitorOptions[collectorName] = metaData[collectorName].options;
                });
                setMetaData(metaData);
                setMonitorOptions(monitorOptions);
            });
        }, []);
    }

    if (!metaData || Object.keys(metaData).length == 0) {
        return <Spinner size={ SpinnerSize.LARGE } />;
    }
    let collectors = Object.keys(metaData).map((collectorName, i) => {
        let collectorOptions = monitorOptions[collectorName];
        return <Collector
                key={`app-collector-${i}`}
                collectorName={collectorName}
                metaData={metaData[collectorName]}
                options={collectorOptions}
                monitorHost={props.monitorHost}
                debug={props.debug}
                snapshotdata={props.snapshotdata}
                onDataChanged={ (data) => {
                    collectorData[collectorName] = data;
                }
            } />;
    });
    return (
        <HotkeysProvider>
            <div id="app">
                <h1 className="bp3-heading">
                    Metrics Monitor
                    {
                        !props.snapshotdata ?
                        <Button onClick={ () => { saveSnapshot(props.bodyHtml, metaData, monitorOptions, collectorData) } }>📥 Save</Button> :
                        ""
                    }
                </h1>

                { collectors }

                <Card style={{display: displayDebug}}>
                    <h3>Metadata</h3>
                    <pre>{JSON.stringify(metaData, null, 4)}</pre>
                </Card>
            </div>
        </HotkeysProvider>
    );
}

export default App;
