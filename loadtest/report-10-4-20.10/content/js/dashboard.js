/*
   Licensed to the Apache Software Foundation (ASF) under one or more
   contributor license agreements.  See the NOTICE file distributed with
   this work for additional information regarding copyright ownership.
   The ASF licenses this file to You under the Apache License, Version 2.0
   (the "License"); you may not use this file except in compliance with
   the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
var showControllersOnly = false;
var seriesFilter = "((^Home page)|(^facet English language)|(^Download)|(^Open search)|(^Subject search - African)|(^load item page))(-success|-failure)?$";
var filtersOnlySampleSeries = true;

/*
 * Add header in statistics table to group metrics by category
 * format
 *
 */
function summaryTableHeader(header) {
    var newRow = header.insertRow(-1);
    newRow.className = "tablesorter-no-sort";
    var cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 1;
    cell.innerHTML = "Requests";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 3;
    cell.innerHTML = "Executions";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 6;
    cell.innerHTML = "Response Times (ms)";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 1;
    cell.innerHTML = "Throughput";
    newRow.appendChild(cell);

    cell = document.createElement('th');
    cell.setAttribute("data-sorter", false);
    cell.colSpan = 2;
    cell.innerHTML = "Network (KB/sec)";
    newRow.appendChild(cell);
}

/*
 * Populates the table identified by id parameter with the specified data and
 * format
 *
 */
function createTable(table, info, formatter, defaultSorts, seriesIndex, headerCreator) {
    var tableRef = table[0];

    // Create header and populate it with data.titles array
    var header = tableRef.createTHead();

    // Call callback is available
    if(headerCreator) {
        headerCreator(header);
    }

    var newRow = header.insertRow(-1);
    for (var index = 0; index < info.titles.length; index++) {
        var cell = document.createElement('th');
        cell.innerHTML = info.titles[index];
        newRow.appendChild(cell);
    }

    var tBody;

    // Create overall body if defined
    if(info.overall){
        tBody = document.createElement('tbody');
        tBody.className = "tablesorter-no-sort";
        tableRef.appendChild(tBody);
        var newRow = tBody.insertRow(-1);
        var data = info.overall.data;
        for(var index=0;index < data.length; index++){
            var cell = newRow.insertCell(-1);
            cell.innerHTML = formatter ? formatter(index, data[index]): data[index];
        }
    }

    // Create regular body
    tBody = document.createElement('tbody');
    tableRef.appendChild(tBody);

    var regexp;
    if(seriesFilter) {
        regexp = new RegExp(seriesFilter, 'i');
    }
    // Populate body with data.items array
    for(var index=0; index < info.items.length; index++){
        var item = info.items[index];
        if((!regexp || filtersOnlySampleSeries && !info.supportsControllersDiscrimination || regexp.test(item.data[seriesIndex]))
                &&
                (!showControllersOnly || !info.supportsControllersDiscrimination || item.isController)){
            if(item.data.length > 0) {
                var newRow = tBody.insertRow(-1);
                for(var col=0; col < item.data.length; col++){
                    var cell = newRow.insertCell(-1);
                    cell.innerHTML = formatter ? formatter(col, item.data[col]) : item.data[col];
                }
            }
        }
    }

    // Add support of columns sort
    table.tablesorter({sortList : defaultSorts});
}

$(document).ready(function() {

    // Customize table sorter default options
    $.extend( $.tablesorter.defaults, {
        theme: 'blue',
        cssInfoBlock: "tablesorter-no-sort",
        widthFixed: true,
        widgets: ['zebra']
    });

    var data = {"OkPercent": 100.0, "KoPercent": 0.0};
    var dataset = [
        {
            "label" : "KO",
            "data" : data.KoPercent,
            "color" : "#FF6347"
        },
        {
            "label" : "OK",
            "data" : data.OkPercent,
            "color" : "#9ACD32"
        }];
    $.plot($("#flot-requests-summary"), dataset, {
        series : {
            pie : {
                show : true,
                radius : 1,
                label : {
                    show : true,
                    radius : 3 / 4,
                    formatter : function(label, series) {
                        return '<div style="font-size:8pt;text-align:center;padding:2px;color:white;">'
                            + label
                            + '<br/>'
                            + Math.round10(series.percent, -2)
                            + '%</div>';
                    },
                    background : {
                        opacity : 0.5,
                        color : '#000'
                    }
                }
            }
        },
        legend : {
            show : true
        }
    });

    // Creates APDEX table
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.7943859649122808, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.175, 500, 1500, "Subject search - African"], "isController": false}, {"data": [0.975, 500, 1500, "load item page-5"], "isController": false}, {"data": [0.945, 500, 1500, "load item page-4"], "isController": false}, {"data": [0.975, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.99, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.415, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.27, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.69, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.68, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.95, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.98, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.925, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.285, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.625, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.835, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.975, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.955, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.175, 500, 1500, "Home page"], "isController": false}, {"data": [0.89, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.13, 500, 1500, "Open search"], "isController": false}, {"data": [0.885, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.895, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.955, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.915, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.99, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.955, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.985, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.745, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.33, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.62, 500, 1500, "Open search-1"], "isController": false}, {"data": [0.995, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.985, 500, 1500, "facet English language-11"], "isController": false}, {"data": [1.0, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.96, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.96, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.14, 500, 1500, "facet English language"], "isController": false}, {"data": [0.95, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.885, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.95, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.98, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.24, 500, 1500, "load item page"], "isController": false}, {"data": [0.97, 500, 1500, "Home page-12"], "isController": false}, {"data": [1.0, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.905, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.92, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.96, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.975, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.955, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.96, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.915, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.945, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.685, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.675, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.315, 500, 1500, "facet English language-2"], "isController": false}, {"data": [0.985, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.98, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.975, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
        switch(index){
            case 0:
                item = item.toFixed(3);
                break;
            case 1:
            case 2:
                item = formatDuration(item);
                break;
        }
        return item;
    }, [[0, 0]], 3);

    // Create statistics table
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 5700, 0, 0.0, 632.6750877192974, 28, 9262, 1600.800000000001, 2767.8499999999995, 4768.909999999998, 43.16317953610941, 13138.767329756281, 45.5606409542849], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 100, 0, 0.0, 2294.5199999999995, 537, 6491, 4557.900000000001, 4729.75, 6487.169999999998, 0.7890168849613381, 1224.264842763729, 1.936327570222503], "isController": false}, {"data": ["load item page-5", 100, 0, 0.0, 170.32, 47, 1118, 341.3000000000002, 548.5999999999985, 1115.6599999999987, 0.8014875609130546, 7.385128673818607, 0.46101188806424725], "isController": false}, {"data": ["load item page-4", 100, 0, 0.0, 239.32999999999984, 32, 1978, 522.0000000000002, 673.8499999999997, 1968.9499999999953, 0.8013398402128358, 16.97794180619997, 0.467187387311585], "isController": false}, {"data": ["load item page-3", 100, 0, 0.0, 162.37000000000003, 28, 1765, 352.40000000000003, 496.09999999999957, 1754.5499999999947, 0.8015967807873283, 0.7815646893612075, 0.5002151786358425], "isController": false}, {"data": ["Subject search - African-3", 100, 0, 0.0, 137.66000000000005, 30, 936, 309.8, 360.95, 932.7699999999984, 0.799130545965989, 0.7791366742983634, 0.49867619030494825], "isController": false}, {"data": ["load item page-2", 100, 0, 0.0, 1468.7899999999993, 312, 7400, 3601.8, 4285.749999999999, 7375.5099999999875, 0.7997888557420841, 959.7891078630241, 0.5006490786432382], "isController": false}, {"data": ["Subject search - African-2", 100, 0, 0.0, 2018.6800000000007, 439, 6406, 4224.300000000001, 4507.7, 6400.519999999997, 0.7896025140944049, 947.5649722578091, 0.49427266751417337], "isController": false}, {"data": ["load item page-1", 100, 0, 0.0, 743.1100000000004, 103, 3830, 1615.7000000000005, 1839.8999999999996, 3812.8099999999913, 0.8001920460910619, 271.47792814025365, 0.5016829038969353], "isController": false}, {"data": ["Subject search - African-1", 100, 0, 0.0, 680.9899999999997, 127, 2647, 1669.5000000000005, 1914.2999999999997, 2646.92, 0.7985115744252712, 270.9077545080969, 0.5006293269345939], "isController": false}, {"data": ["load item page-0", 100, 0, 0.0, 333.6899999999999, 133, 1343, 546.4000000000003, 666.5499999999997, 1342.9099999999999, 0.7987220447284344, 20.92617437100639, 0.45084115415335463], "isController": false}, {"data": ["Subject search - African-0", 100, 0, 0.0, 192.1, 63, 831, 346.1, 473.74999999999994, 829.8199999999994, 0.7988305121302414, 9.058129523377774, 0.46104378190329354], "isController": false}, {"data": ["Home page-0", 100, 0, 0.0, 315.55, 101, 1104, 687.6, 768.95, 1101.2099999999987, 0.7937704892007524, 14.77492141672157, 0.39735034449639234], "isController": false}, {"data": ["Home page-2", 100, 0, 0.0, 2084.539999999999, 302, 7086, 4124.9000000000015, 5341.899999999995, 7082.839999999998, 0.7926128482542701, 951.1776260873658, 0.4874878631157611], "isController": false}, {"data": ["Home page-1", 100, 0, 0.0, 770.8700000000002, 176, 2843, 1615.2000000000003, 1921.9999999999998, 2835.529999999996, 0.7961973614019443, 270.12269867861096, 0.4904700152073696], "isController": false}, {"data": ["Home page-4", 100, 0, 0.0, 543.8900000000001, 128, 4270, 1230.4, 1402.4999999999995, 4245.579999999987, 0.7946093700336915, 122.59186025751303, 0.1505412283071642], "isController": false}, {"data": ["Home page-3", 100, 0, 0.0, 202.41999999999993, 28, 1228, 467.9, 550.8999999999993, 1221.919999999997, 0.7979190271771222, 0.7781191028796898, 0.48919293482597387], "isController": false}, {"data": ["Home page-6", 100, 0, 0.0, 256.87, 49, 1228, 488.0, 829.4999999999987, 1227.7299999999998, 0.7965461757818101, 6.729803945094072, 0.4494574027018846], "isController": false}, {"data": ["Home page", 100, 0, 0.0, 2512.019999999999, 705, 7255, 4589.5, 5646.699999999997, 7251.279999999998, 0.7879537628731946, 1498.9009276185673, 5.998298019872194], "isController": false}, {"data": ["Home page-5", 100, 0, 0.0, 384.8199999999999, 51, 2632, 1006.7, 1199.4999999999995, 2623.1099999999956, 0.7961466502129693, 28.457103556287567, 0.44923196727837267], "isController": false}, {"data": ["Open search", 100, 0, 0.0, 2615.01, 745, 9262, 4586.3, 5391.65, 9254.349999999997, 0.7914084696534421, 1485.8754146238437, 6.465590796315202], "isController": false}, {"data": ["Home page-8", 100, 0, 0.0, 394.3000000000001, 106, 1750, 704.7000000000002, 1015.4499999999971, 1748.9499999999994, 0.7965398309742479, 25.696787218821438, 0.44945382259464883], "isController": false}, {"data": ["Home page-7", 100, 0, 0.0, 384.79000000000013, 172, 1714, 586.3000000000001, 736.5999999999999, 1713.2899999999997, 0.7977407980598943, 14.761944174098952, 0.4501314776552803], "isController": false}, {"data": ["Home page-9", 100, 0, 0.0, 278.56999999999994, 54, 1417, 469.5000000000001, 597.3999999999996, 1414.1599999999985, 0.7981164451893531, 7.345734379364699, 0.4503434394828205], "isController": false}, {"data": ["Open search-4", 100, 0, 0.0, 303.80999999999995, 50, 880, 647.0000000000002, 731.2499999999995, 879.0999999999996, 0.7966730931629515, 25.707248094457544, 0.4559086255795797], "isController": false}, {"data": ["Open search-3", 100, 0, 0.0, 168.10999999999999, 34, 598, 326.00000000000006, 489.64999999999947, 598.0, 0.7971938775510204, 0.7774586580237564, 0.4951321348852041], "isController": false}, {"data": ["Open search-6", 100, 0, 0.0, 234.34999999999994, 50, 747, 496.8, 513.9, 745.7899999999994, 0.7969016463988015, 8.7867823029063, 0.4560394187399391], "isController": false}, {"data": ["Open search-5", 100, 0, 0.0, 209.29999999999998, 44, 1159, 315.30000000000007, 467.4999999999999, 1153.6199999999972, 0.7970795007094007, 7.342456613966427, 0.45614119864815317], "isController": false}, {"data": ["Open search-0", 100, 0, 0.0, 526.0199999999998, 247, 1744, 765.9000000000001, 951.55, 1737.2999999999965, 0.7952286282306164, 49.53383604622267, 0.46036282306163023], "isController": false}, {"data": ["Open search-2", 100, 0, 0.0, 1914.31, 304, 8921, 4100.3, 5061.299999999996, 8911.009999999995, 0.794710407527497, 953.6948865228043, 0.4951418359399835], "isController": false}, {"data": ["Open search-1", 100, 0, 0.0, 804.4300000000001, 102, 3207, 1601.6, 1983.549999999998, 3203.459999999998, 0.7957855198866802, 269.98316136491144, 0.49658881563241075], "isController": false}, {"data": ["facet English language-13", 100, 0, 0.0, 103.34000000000002, 42, 535, 181.70000000000002, 209.44999999999987, 532.4899999999986, 0.7992966189753017, 5.446855204919671, 0.45975166853169214], "isController": false}, {"data": ["facet English language-11", 100, 0, 0.0, 153.85999999999996, 44, 566, 332.70000000000005, 436.2499999999994, 565.6399999999999, 0.7982948422170245, 10.067043669721475, 0.4591754512361596], "isController": false}, {"data": ["facet English language-12", 100, 0, 0.0, 105.64000000000001, 44, 398, 198.8, 235.99999999999977, 397.7899999999999, 0.7992966189753017, 8.960950301234913, 0.45975166853169214], "isController": false}, {"data": ["Open search-8", 100, 0, 0.0, 257.5, 49, 627, 460.8, 553.5499999999995, 626.81, 0.7964700447616164, 10.152566326042978, 0.45579242795928443], "isController": false}, {"data": ["Open search-7", 100, 0, 0.0, 251.78, 54, 870, 467.10000000000014, 654.7499999999991, 869.6599999999999, 0.7967619593970106, 9.035086097599356, 0.45595948067055486], "isController": false}, {"data": ["facet English language", 100, 0, 0.0, 2567.37, 925, 8046, 4962.500000000001, 5311.799999999999, 8043.1799999999985, 0.7915212246416388, 1382.8074370468541, 6.527731193455702], "isController": false}, {"data": ["facet English language-10", 100, 0, 0.0, 262.1300000000002, 46, 1332, 512.8000000000004, 744.6499999999978, 1330.1699999999992, 0.7986965272674994, 8.553899411160986, 0.4594064985942941], "isController": false}, {"data": ["Open search-9", 100, 0, 0.0, 411.46999999999997, 100, 1614, 691.4000000000001, 954.0999999999993, 1611.1099999999985, 0.7960262370247724, 39.59361430240241, 0.45553845204737947], "isController": false}, {"data": ["Home page-10", 100, 0, 0.0, 232.28000000000014, 41, 837, 497.3000000000002, 554.75, 836.1399999999995, 0.7993732913395898, 8.807548007362229, 0.4510526247422021], "isController": false}, {"data": ["Home page-11", 100, 0, 0.0, 157.31, 50, 1175, 275.5, 443.7999999999993, 1171.0599999999981, 0.7992646764976222, 9.056574201734405, 0.4509913379690685], "isController": false}, {"data": ["load item page", 100, 0, 0.0, 1938.1300000000003, 486, 7825, 3952.6, 4604.449999999999, 7798.8399999999865, 0.7966857871255576, 1272.2234566702518, 2.867757628266412], "isController": false}, {"data": ["Home page-12", 100, 0, 0.0, 208.6, 52, 1084, 393.9, 591.1499999999994, 1079.7499999999977, 0.7995330726855516, 33.16267206201579, 0.4511427826149529], "isController": false}, {"data": ["Home page-13", 100, 0, 0.0, 123.85999999999997, 48, 372, 245.0, 266.79999999999995, 371.9, 0.7993988520632485, 16.863037745615298, 0.4510670475802197], "isController": false}, {"data": ["facet English language-8", 100, 0, 0.0, 359.8999999999999, 97, 1029, 685.8000000000002, 793.5999999999999, 1028.2199999999996, 0.7980845969672786, 16.844721106843576, 0.45905451915403034], "isController": false}, {"data": ["facet English language-9", 100, 0, 0.0, 356.23999999999995, 96, 957, 636.2, 813.0999999999998, 957.0, 0.7981164451893531, 28.119536331757054, 0.4590728381020791], "isController": false}, {"data": ["facet English language-4", 100, 0, 0.0, 226.38999999999987, 44, 883, 460.80000000000024, 571.0499999999995, 881.4599999999992, 0.7983840706410226, 7.356820732337749, 0.45922677500738507], "isController": false}, {"data": ["facet English language-5", 100, 0, 0.0, 218.33000000000004, 47, 698, 377.00000000000017, 520.3999999999994, 697.8799999999999, 0.7984031936127745, 8.805716691616766, 0.4592377744510978], "isController": false}, {"data": ["Open search-11", 100, 0, 0.0, 248.21000000000015, 54, 983, 467.0, 622.9999999999998, 980.4899999999986, 0.7973909368546117, 33.08026917176997, 0.4563194228484399], "isController": false}, {"data": ["facet English language-6", 100, 0, 0.0, 228.51999999999995, 41, 936, 447.2000000000001, 529.9, 932.8099999999984, 0.7983904448631559, 9.055876166149044, 0.45923044143007696], "isController": false}, {"data": ["Open search-10", 100, 0, 0.0, 334.2299999999999, 89, 948, 621.7, 674.8, 947.1999999999996, 0.7961086210602575, 35.69631329561105, 0.4555855975989364], "isController": false}, {"data": ["facet English language-7", 100, 0, 0.0, 285.06000000000006, 113, 1153, 528.2, 595.5999999999999, 1149.7899999999984, 0.7983267072216634, 10.178665517076208, 0.4591937798374607], "isController": false}, {"data": ["facet English language-0", 100, 0, 0.0, 576.4400000000002, 262, 1408, 875.1000000000001, 1011.699999999999, 1406.269999999999, 0.7950895270807493, 51.44917955457097, 0.49149577211143974], "isController": false}, {"data": ["facet English language-1", 100, 0, 0.0, 719.46, 121, 2953, 1542.5000000000011, 1998.5999999999985, 2951.119999999999, 0.7958045185780565, 269.98959143644703, 0.49893212981163304], "isController": false}, {"data": ["facet English language-2", 100, 0, 0.0, 1873.2199999999996, 331, 7508, 4381.400000000001, 4771.85, 7505.399999999999, 0.7972892166633446, 956.7897196407216, 0.4990843631652382], "isController": false}, {"data": ["facet English language-3", 100, 0, 0.0, 173.02, 28, 821, 301.6, 463.7999999999997, 820.0299999999995, 0.7984350672681544, 0.7787237015449718, 0.4982421952972174], "isController": false}, {"data": ["Open search-13", 100, 0, 0.0, 153.93000000000012, 39, 1031, 334.00000000000017, 424.0999999999998, 1027.4199999999983, 0.7963114852005511, 16.80435752842832, 0.4557016897729716], "isController": false}, {"data": ["Open search-12", 100, 0, 0.0, 190.71999999999997, 51, 804, 352.6, 526.2999999999996, 802.5399999999993, 0.797232010459684, 32.81818806354338, 0.4562284747357176], "isController": false}]}, function(index, item){
        switch(index){
            // Errors pct
            case 3:
                item = item.toFixed(2) + '%';
                break;
            // Mean
            case 4:
            // Mean
            case 7:
            // Percentile 1
            case 8:
            // Percentile 2
            case 9:
            // Percentile 3
            case 10:
            // Throughput
            case 11:
            // Kbytes/s
            case 12:
            // Sent Kbytes/s
                item = item.toFixed(2);
                break;
        }
        return item;
    }, [[0, 0]], 0, summaryTableHeader);

    // Create error table
    createTable($("#errorsTable"), {"supportsControllersDiscrimination": false, "titles": ["Type of error", "Number of errors", "% in errors", "% in all samples"], "items": []}, function(index, item){
        switch(index){
            case 2:
            case 3:
                item = item.toFixed(2) + '%';
                break;
        }
        return item;
    }, [[1, 1]]);

        // Create top5 errors by sampler
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 5700, 0, null, null, null, null, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
