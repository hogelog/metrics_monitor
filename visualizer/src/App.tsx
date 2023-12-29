import { useState, useEffect } from 'react';

import { Card, Spinner, SpinnerSize } from "@blueprintjs/core";

import Collector from './Collector';

function App(props: { monitorHost: string, debug: boolean }) {
    const [displayDebug] = useState(props.debug ? "block" : "none");

    const [metaData, setMetaData] = useState({} as { [key: string]: CollectorMetaData });

    const [monitorOptions, setMonitorOptions] = useState({} as MonitorOptions);

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

    if (!metaData || Object.keys(metaData).length == 0) {
        return <Spinner size={ SpinnerSize.LARGE } />;
    }
    let collectors = Object.keys(metaData).map((collectorName, i) => {
        let collectorOptions = monitorOptions[collectorName];
        return (
            <Collector key={`app-collector-${i}`} collectorName={collectorName} metaData={metaData[collectorName]} options={collectorOptions} monitorHost={props.monitorHost} debug={props.debug} />
        );
    });
    return (
        <div id="app">
            { collectors }

            <Card style={{display: displayDebug}}>
                <h3>Metadata</h3>
                <pre>{JSON.stringify(metaData, null, 4)}</pre>
            </Card>
        </div>
    );
}

export default App;
