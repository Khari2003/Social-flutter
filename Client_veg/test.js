const haversine = require("haversine-distance");

// Hàm tính khoảng cách giữa hai tọa độ
function calculateDistance(coord1, coord2) {
    if (!coord1 || !coord2 || !coord1.lat || !coord1.lon || !coord2.lat || !coord2.lon) {
        throw new Error("Invalid coordinates provided to calculateDistance");
    }
    return haversine(
        { latitude: coord1.lat, longitude: coord1.lon },
        { latitude: coord2.lat, longitude: coord2.lon }
    );
}

// Hàm xây dựng đồ thị từ dữ liệu JSON
function buildGraph(elements) {
    const nodes = {};
    const graph = {};

    elements.forEach((element) => {
        if (element.type === "node") {
            nodes[element.id] = { lat: element.lat, lon: element.lon };
        }
    });

    elements.forEach((element) => {
        if (element.type === "way") {
            const wayNodes = element.nodes;
            for (let i = 0; i < wayNodes.length - 1; i++) {
                const node1 = wayNodes[i];
                const node2 = wayNodes[i + 1];

                if (!nodes[node1] || !nodes[node2]) {
                    console.warn(`Node ${node1} or ${node2} not found.`);
                    continue;
                }

                if (!graph[node1]) graph[node1] = {};
                if (!graph[node2]) graph[node2] = {};

                const distance = calculateDistance(nodes[node1], nodes[node2]);

                graph[node1][node2] = distance;
                if (element.tags.oneway !== "yes") {
                    graph[node2][node1] = distance;
                }
            }
        }
    });

    return { graph, nodes };
}

// Thuật toán Dijkstra
function dijkstra(graph, start) {
    const distances = {};
    const previous = {};
    const visited = new Set();
    const priorityQueue = [];

    for (let node in graph) {
        distances[node] = Infinity;
        previous[node] = null;
    }
    distances[start] = 0;
    priorityQueue.push({ node: start, distance: 0 });

    while (priorityQueue.length > 0) {
        priorityQueue.sort((a, b) => a.distance - b.distance);
        const current = priorityQueue.shift().node;

        if (visited.has(current)) continue;
        visited.add(current);

        for (let neighbor in graph[current]) {
            const distance = graph[current][neighbor];
            const newDistance = distances[current] + distance;

            if (newDistance < distances[neighbor]) {
                distances[neighbor] = newDistance;
                previous[neighbor] = current;
                priorityQueue.push({ node: neighbor, distance: newDistance });
            }
        }
    }

    return { distances, previous };
}

// Hàm truy ngược đường đi từ điểm kết thúc
function getPath(previous, start, end) {
    const path = [];
    let currentNode = end;

    while (currentNode && currentNode !== start) {
        path.unshift(currentNode); // Thêm node vào đầu mảng
        currentNode = previous[currentNode];
    }
    if (currentNode === start) {
        path.unshift(start); // Thêm điểm bắt đầu vào đầu đường đi
    }

    return path;
}

// Dữ liệu JSON
const elements = [
    { type: "node", id: 75617751, lat: 21.025479, lon: 105.8532306 },
    { type: "node", id: 8932529787, lat: 21.0251, lon: 105.8531 },
    { type: "node", id: 84798025, lat: 21.0252, lon: 105.8532 },
    { type: "node", id: 1497603121, lat: 21.0253, lon: 105.8533 },
    { type: "node", id: 84798024, lat: 21.0254, lon: 105.8534 },
    { type: "node", id: 84798023, lat: 21.0255, lon: 105.8535 },
    { type: "node", id: 84796872, lat: 21.0256, lon: 105.8536 },
    {
        type: "way",
        id: 10231922,
        nodes: [8932529787, 84798025, 1497603121, 84798024, 84798023, 84796872],
        tags: {
            bridge: "yes",
            highway: "primary_link",
            lanes: "2",
            layer: "1",
            oneway: "yes",
            surface: "asphalt",
        },
    },
];

// Xây dựng đồ thị
const { graph, nodes } = buildGraph(elements);

// Gọi thuật toán Dijkstra
const startPoint = 8932529787;
const endPoint = 84796872; // Đích đến
const { distances, previous } = dijkstra(graph, startPoint);

// Truy ngược đường đi từ điểm bắt đầu tới điểm kết thúc
const path = getPath(previous, startPoint, endPoint);

// In kết quả
if (distances[endPoint] === Infinity) {
    console.log(`Không có đường đi từ node ${startPoint} đến node ${endPoint}.`);
} else {
    console.log(`Node bắt đầu: ${startPoint}`);
    console.log(`Node kết thúc: ${endPoint}`);
    console.log(`Các node đi qua: ${path.join(" -> ")}`);
    console.log(`Tổng khoảng cách: ${distances[endPoint].toFixed(2)} m`);
}
