interface CollectorData {
    [pid: string]: {
        [key: string]: (number | Date)[]
    }
}

interface CollectorMetaData {
    title: string;
    monitors: MonitorFormat[];
    data: DataFormat[];
    key: string;
    options: CollectorOptions;
}

interface MonitorFormat {
    key: string;
    title: string;
    type: "chart" | "table" | "text";
    mode: "line" | "area";
}

interface DataFormat {
    [name: string]: {
        mode: "overwrite" | "append";
    };
}

interface MonitorChartData {
    ts: number;
    data: {
        [name: string]: number;
    };
    error?: string;
}

interface MonitorData {
    [pid: string]: MonitorChartData[];
}

interface CollectorOptions {
    enabled: boolean;
    [key: string]: any;
}

interface MonitorOptions {
    [key: string]: CollectorOptions;
}
