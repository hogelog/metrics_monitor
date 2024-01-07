type CollectorDataValue = number | Date | [string, number];

interface CollectorPidData {
    date: Date[];
    [key: string]: CollectorDataValue[];
}

interface CollectorData {
    [pid: string]: CollectorPidData;
}

interface CollectorMetaData {
    title: string;
    monitors: MonitorFormat[];
    data: DataFormat[];
    key: string;
    options: CollectorOptions;
    layout: "default" | "large";
}

interface MonitorFormat {
    key: string;
    title: string;
    type: "chart" | "table" | "text";
    mode: "line" | "area" | "stacked_bar";
    size: "medium" | "full";
    hovertemplate?: string;
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
