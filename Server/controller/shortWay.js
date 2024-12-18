const haversine = require("haversine-distance");

function shortWay(elements, startCoord, endCoord) {
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

    // Hàm tìm node gần nhất với toạ độ
    function findNearestNode(coord, nodes) {
        let nearestNode = null;
        let minDistance = Infinity;

        for (const [nodeId, nodeCoord] of Object.entries(nodes)) {
            const distance = calculateDistance(coord, nodeCoord);
            if (distance < minDistance) {
                minDistance = distance;
                nearestNode = nodeId;
            }
        }

        return nearestNode;
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
            path.unshift(currentNode);
            currentNode = previous[currentNode];
        }
        if (currentNode === start) {
            path.unshift(start);
        }

        return path;
    }

    // Xây dựng đồ thị
    const { graph, nodes } = buildGraph(elements);

    // Tìm node gần nhất với startCoord và endCoord
    const startPoint = findNearestNode(startCoord, nodes);
    const endPoint = findNearestNode(endCoord, nodes);

    if (!startPoint || !endPoint) {
        return {
            path: null,
            distance: Infinity,
            message: "Không tìm thấy node gần nhất cho toạ độ được cung cấp."
        };
    }

    // Gọi thuật toán Dijkstra
    const { distances, previous } = dijkstra(graph, startPoint);

    // Truy ngược đường đi từ điểm bắt đầu tới điểm kết thúc
    const path = getPath(previous, startPoint, endPoint);

    // Kết quả
    if (distances[endPoint] === Infinity) {
        return {
            path: null,
            distance: Infinity,
            message: `Không có đường đi từ toạ độ ${JSON.stringify(startCoord)} đến toạ độ ${JSON.stringify(endCoord)}.`
        };
    } else {
        return {
            path,
            distance: distances[endPoint],
            message: `Tìm được đường đi từ toạ độ ${JSON.stringify(startCoord)} đến toạ độ ${JSON.stringify(endCoord)}.`
        };
    }
}

module.exports = shortWay