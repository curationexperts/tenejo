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

    var data = {"OkPercent": 99.9298245614035, "KoPercent": 0.07017543859649122};
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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.7026315789473684, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.0025, 500, 1500, "Subject search - African"], "isController": false}, {"data": [0.9375, 500, 1500, "load item page-5"], "isController": false}, {"data": [0.9325, 500, 1500, "load item page-4"], "isController": false}, {"data": [0.9425, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.9525, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.015, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.005, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.3275, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.3725, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.9225, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.955, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.8725, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.0, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.3275, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.8225, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.9275, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.9025, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.0, 500, 1500, "Home page"], "isController": false}, {"data": [0.82, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.0, 500, 1500, "Open search"], "isController": false}, {"data": [0.8625, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.885, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.9275, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.8875, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.9675, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.9525, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.965, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.505, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.0025, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.275, 500, 1500, "Open search-1"], "isController": false}, {"data": [0.9925, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.9875, 500, 1500, "facet English language-11"], "isController": false}, {"data": [0.995, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.9475, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.9325, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.0, 500, 1500, "facet English language"], "isController": false}, {"data": [0.9525, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.86, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.9675, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.9825, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.0075, 500, 1500, "load item page"], "isController": false}, {"data": [0.965, 500, 1500, "Home page-12"], "isController": false}, {"data": [0.97, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.94, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.8975, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.9275, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.95, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.9625, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.9575, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.92, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.9375, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.505, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.315, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.0025, 500, 1500, "facet English language-2"], "isController": false}, {"data": [0.9575, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.9875, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.9625, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 11400, 8, 0.07017543859649122, 1175.3373684210521, 29, 12957, 4299.9, 5358.899999999998, 7247.939999999999, 44.00507988466037, 13389.551245290686, 46.43228030753375], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 200, 0, 0.0, 4659.825000000001, 1476, 8870, 6483.6, 7026.099999999999, 8578.230000000007, 0.7982757244352199, 1238.6323354055241, 1.9590497026422926], "isController": false}, {"data": ["load item page-5", 200, 0, 0.0, 277.4700000000001, 51, 1231, 531.1, 622.6499999999994, 920.4700000000005, 0.8257399662272354, 7.609016383713105, 0.4749617579178141], "isController": false}, {"data": ["load item page-4", 200, 0, 0.0, 314.555, 78, 1736, 529.2, 641.4499999999994, 1683.2400000000016, 0.825695648583932, 17.49431769801214, 0.4813870138716869], "isController": false}, {"data": ["load item page-3", 200, 0, 0.0, 231.6600000000001, 30, 1034, 523.6, 582.0, 1016.4400000000014, 0.8260127949381936, 0.8057053026407629, 0.5154513437163142], "isController": false}, {"data": ["Subject search - African-3", 200, 0, 0.0, 225.6600000000001, 29, 1154, 498.5, 573.3499999999999, 1113.0300000000009, 0.8026938405288147, 0.7829400467970509, 0.5008997696268678], "isController": false}, {"data": ["load item page-2", 200, 0, 0.0, 4303.6399999999985, 917, 12544, 6086.1, 7296.149999999998, 11037.470000000023, 0.8229978519756064, 987.6414334667961, 0.5151773663245739], "isController": false}, {"data": ["Subject search - African-2", 200, 0, 0.0, 4355.205, 1235, 8551, 6172.3, 6695.499999999998, 8327.150000000007, 0.7991912184868912, 959.0721806719101, 0.5002749717286107], "isController": false}, {"data": ["load item page-1", 200, 0, 0.0, 1432.5100000000014, 378, 4888, 2227.9, 2859.5499999999984, 3354.59, 0.8246640524816203, 279.78062019504335, 0.5170257047785158], "isController": false}, {"data": ["Subject search - African-1", 200, 0, 0.0, 1322.199999999999, 590, 3673, 2049.4, 2515.849999999999, 3380.1100000000015, 0.8012371100979913, 271.83255321215955, 0.5023381100419047], "isController": false}, {"data": ["load item page-0", 200, 0, 0.0, 418.4550000000001, 146, 1146, 640.5, 757.7499999999998, 1068.9700000000018, 0.8239472014633302, 21.587565535987952, 0.4650795727009813], "isController": false}, {"data": ["Subject search - African-0", 200, 0, 0.0, 299.3450000000001, 77, 2015, 449.40000000000003, 633.8, 768.7300000000002, 0.8023235289398096, 9.098211702339976, 0.4630597710970972], "isController": false}, {"data": ["Home page-0", 200, 0, 0.0, 447.3100000000002, 229, 2681, 745.7, 900.9499999999998, 1960.3200000000006, 0.8052858966254495, 14.989642010154654, 0.4031147955177787], "isController": false}, {"data": ["Home page-2", 200, 0, 0.0, 4620.214999999997, 1637, 10807, 6784.5, 7557.949999999999, 8835.19, 0.7979158438159527, 957.5417369206633, 0.49074941253446003], "isController": false}, {"data": ["Home page-1", 200, 2, 1.0, 1438.3500000000006, 148, 4503, 2246.5, 2577.8, 4465.150000000001, 0.8038617518559159, 270.01262110051687, 0.49103078690026886], "isController": false}, {"data": ["Home page-4", 200, 0, 0.0, 540.9999999999997, 183, 2177, 1075.5, 1381.3999999999999, 1988.1700000000008, 0.8048419290451355, 124.17095386470002, 0.1524798185886292], "isController": false}, {"data": ["Home page-3", 200, 0, 0.0, 260.5399999999999, 32, 2289, 554.3000000000001, 697.6499999999999, 1693.1800000000044, 0.8061330603229369, 0.7862828209518012, 0.4942288430378318], "isController": false}, {"data": ["Home page-6", 200, 0, 0.0, 359.8750000000001, 60, 1954, 693.8, 931.95, 1853.9500000000046, 0.8061298110834787, 6.810989986608169, 0.454865043793002], "isController": false}, {"data": ["Home page", 200, 2, 1.0, 5079.575000000001, 2328, 11619, 7208.3, 7980.249999999999, 9624.65, 0.7960230687485323, 1511.5680342260068, 6.055605569574406], "isController": false}, {"data": ["Home page-5", 200, 0, 0.0, 527.1449999999996, 100, 2676, 933.1, 1370.7499999999993, 2199.2200000000016, 0.8055129304963168, 28.791887616346276, 0.4545169641023163], "isController": false}, {"data": ["Open search", 200, 2, 1.0, 5193.865, 2275, 9951, 7097.100000000001, 8484.85, 9820.900000000003, 0.7945336087716511, 1491.5934542224495, 6.486474617134117], "isController": false}, {"data": ["Home page-8", 200, 0, 0.0, 448.08000000000015, 105, 2066, 717.0, 912.1999999999996, 1929.4800000000014, 0.8061428081984724, 26.006599979342592, 0.4548723775166771], "isController": false}, {"data": ["Home page-7", 200, 0, 0.0, 402.35499999999985, 162, 1887, 783.1000000000001, 882.2999999999998, 1580.5800000000022, 0.8053150795248641, 14.902103885645259, 0.4544053251459634], "isController": false}, {"data": ["Home page-9", 200, 0, 0.0, 278.1100000000001, 51, 1445, 588.1, 693.8, 1208.8000000000002, 0.8065426741728905, 7.423201384632136, 0.4550980050166954], "isController": false}, {"data": ["Open search-4", 200, 0, 0.0, 410.11499999999995, 111, 1831, 710.8, 882.5999999999995, 1765.3700000000033, 0.804495520971187, 25.9598095092879, 0.4603851321182769], "isController": false}, {"data": ["Open search-3", 200, 1, 0.5, 206.6, 29, 923, 346.8000000000003, 518.1499999999999, 695.6700000000003, 0.804608799201828, 0.7893338040294808, 0.4973448852527276], "isController": false}, {"data": ["Open search-6", 200, 0, 0.0, 277.8849999999998, 55, 1343, 492.9, 612.95, 1245.2100000000016, 0.8045019931536881, 8.870706881961457, 0.460388835925841], "isController": false}, {"data": ["Open search-5", 200, 0, 0.0, 271.34999999999997, 55, 1950, 435.5000000000002, 596.2999999999996, 1400.680000000002, 0.8046444075202067, 7.412279772597433, 0.46047033477230576], "isController": false}, {"data": ["Open search-0", 200, 0, 0.0, 723.3900000000006, 484, 1809, 992.4000000000001, 1160.4999999999995, 1761.4800000000014, 0.8031709187873726, 50.029234166489296, 0.4649606647042524], "isController": false}, {"data": ["Open search-2", 200, 0, 0.0, 4461.8099999999995, 1383, 9277, 6209.0, 7880.649999999998, 8913.52, 0.7964700447616164, 955.8066500830818, 0.49623817241983526], "isController": false}, {"data": ["Open search-1", 200, 0, 0.0, 1554.5700000000006, 610, 5747, 2346.1000000000004, 2629.3499999999995, 4740.170000000003, 0.8018410269979873, 272.0375826647984, 0.5003675939958144], "isController": false}, {"data": ["facet English language-13", 200, 0, 0.0, 104.35000000000001, 44, 614, 188.90000000000006, 230.89999999999998, 584.95, 0.8142261594580511, 5.5485855110490485, 0.4683390702351485], "isController": false}, {"data": ["facet English language-11", 200, 0, 0.0, 116.23, 47, 1070, 206.50000000000009, 260.4999999999999, 610.5700000000004, 0.8142957766549543, 10.268659396871476, 0.4683791137204767], "isController": false}, {"data": ["facet English language-12", 200, 0, 0.0, 105.71500000000002, 47, 549, 182.70000000000002, 257.0, 510.7800000000011, 0.8142261594580511, 9.128302195967953, 0.4683390702351485], "isController": false}, {"data": ["Open search-8", 200, 0, 0.0, 290.56499999999994, 57, 1327, 539.2000000000003, 659.2999999999998, 1310.6000000000022, 0.8042431870549017, 10.251724818894488, 0.4602407300919652], "isController": false}, {"data": ["Open search-7", 200, 0, 0.0, 305.135, 129, 1630, 578.7, 838.2999999999989, 1391.2300000000007, 0.8041720445672147, 9.11918533351025, 0.460200017691785], "isController": false}, {"data": ["facet English language", 200, 0, 0.0, 4957.720000000002, 1507, 9674, 6602.4, 7448.099999999999, 9182.250000000007, 0.8074511592980019, 1410.6372827199395, 6.65910648464026], "isController": false}, {"data": ["facet English language-10", 200, 0, 0.0, 226.16000000000003, 52, 1817, 480.40000000000015, 564.0, 1409.3600000000015, 0.8133453708448218, 8.710646951429048, 0.4678324447535157], "isController": false}, {"data": ["Open search-9", 200, 0, 0.0, 447.72499999999997, 148, 1757, 694.7, 833.8, 1295.2700000000007, 0.8039780835574423, 39.98920251152703, 0.4600890204733019], "isController": false}, {"data": ["Home page-10", 200, 0, 0.0, 210.7549999999999, 46, 783, 484.2000000000001, 559.9, 720.0, 0.8072751637759489, 8.894508876494973, 0.4555113179977961], "isController": false}, {"data": ["Home page-11", 200, 0, 0.0, 143.2400000000001, 48, 901, 261.9, 351.39999999999986, 719.97, 0.8072751637759489, 9.147290853925577, 0.4555113179977961], "isController": false}, {"data": ["load item page", 200, 0, 0.0, 4723.065000000001, 1128, 12957, 6451.1, 7791.199999999999, 11383.730000000021, 0.8208428414295799, 1310.801801211359, 2.9547135874115544], "isController": false}, {"data": ["Home page-12", 200, 0, 0.0, 276.155, 137, 1195, 445.40000000000015, 651.2499999999998, 919.4200000000014, 0.8077152965122854, 33.50195994009781, 0.455759666332811], "isController": false}, {"data": ["Home page-13", 200, 0, 0.0, 201.79, 86, 826, 358.70000000000005, 518.2499999999998, 683.8900000000001, 0.8083682278951708, 17.05218831594668, 0.45612808796663057], "isController": false}, {"data": ["facet English language-8", 200, 0, 0.0, 336.59999999999985, 143, 1577, 537.5, 807.0999999999991, 1113.3000000000006, 0.8132097796608102, 17.163812882716854, 0.4677544533400559], "isController": false}, {"data": ["facet English language-9", 200, 0, 0.0, 400.51000000000005, 89, 1873, 665.7, 756.8499999999999, 1852.8600000000056, 0.8130874556867337, 28.646960856953523, 0.4676840931635607], "isController": false}, {"data": ["facet English language-4", 200, 0, 0.0, 268.535, 49, 2062, 561.8, 602.9, 1100.4000000000024, 0.8128594362819809, 7.490130584598346, 0.4675529374707879], "isController": false}, {"data": ["facet English language-5", 200, 0, 0.0, 260.9449999999999, 61, 1425, 503.9000000000001, 622.6499999999999, 1346.690000000002, 0.8128561325930923, 8.965180005720475, 0.4675510372044252], "isController": false}, {"data": ["Open search-11", 200, 0, 0.0, 301.5949999999999, 103, 2138, 417.70000000000005, 642.9499999999996, 2124.770000000007, 0.8045699573577924, 33.3780561086974, 0.4604277295035803], "isController": false}, {"data": ["facet English language-6", 200, 0, 0.0, 253.67999999999986, 55, 1463, 480.80000000000007, 566.5999999999999, 703.4900000000005, 0.8128528289310579, 9.219977693540258, 0.4675491369535089], "isController": false}, {"data": ["Open search-10", 200, 0, 0.0, 385.0499999999999, 145, 2171, 668.0000000000002, 845.2999999999998, 1535.8500000000001, 0.8039813154742284, 36.04931307333918, 0.4600908699881815], "isController": false}, {"data": ["facet English language-7", 200, 0, 0.0, 304.2549999999996, 116, 1457, 533.7, 648.9499999999998, 1319.4100000000005, 0.8137358613394092, 10.375132232077467, 0.46805705305557815], "isController": false}, {"data": ["facet English language-0", 200, 0, 0.0, 708.025, 342, 1813, 952.1, 1053.8, 1537.4700000000023, 0.8112668743509865, 52.49624361254097, 0.5014960268204829], "isController": false}, {"data": ["facet English language-1", 200, 0, 0.0, 1426.0400000000006, 441, 4326, 2176.7000000000003, 2417.8499999999995, 3779.2000000000025, 0.8118233959384475, 275.42428713026516, 0.5089752150317219], "isController": false}, {"data": ["facet English language-2", 200, 0, 0.0, 4228.654999999998, 1163, 8764, 5979.1, 6704.499999999999, 8540.880000000006, 0.8094511516466261, 971.3846409742656, 0.5066974494194212], "isController": false}, {"data": ["facet English language-3", 200, 0, 0.0, 228.775, 29, 2054, 479.0, 555.9499999999998, 1104.9100000000028, 0.8131833281154071, 0.7932071302455407, 0.5074454557282666], "isController": false}, {"data": ["Open search-13", 200, 0, 0.0, 180.07499999999993, 49, 1726, 273.9000000000001, 378.69999999999993, 731.0500000000018, 0.8042949349526471, 16.972704554822755, 0.46027034363501096], "isController": false}, {"data": ["Open search-12", 200, 1, 0.5, 260.22000000000014, 55, 1263, 418.8000000000001, 573.1499999999999, 881.4400000000005, 0.8043272807705456, 32.953111961100724, 0.4579756276266313], "isController": false}]}, function(index, item){
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
    createTable($("#errorsTable"), {"supportsControllersDiscrimination": false, "titles": ["Type of error", "Number of errors", "% in errors", "% in all samples"], "items": [{"data": ["Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 4, 50.0, 0.03508771929824561], "isController": false}, {"data": ["Assertion failed", 4, 50.0, 0.03508771929824561], "isController": false}]}, function(index, item){
        switch(index){
            case 2:
            case 3:
                item = item.toFixed(2) + '%';
                break;
        }
        return item;
    }, [[1, 1]]);

        // Create top5 errors by sampler
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 11400, 8, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 4, "Assertion failed", 4, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["Home page-1", 200, 2, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 2, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["Home page", 200, 2, "Assertion failed", 2, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": ["Open search", 200, 2, "Assertion failed", 2, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["Open search-3", 200, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["Open search-12", 200, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
