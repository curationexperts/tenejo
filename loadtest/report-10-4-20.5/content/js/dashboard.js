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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.852280701754386, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.46, 500, 1500, "Subject search - African"], "isController": false}, {"data": [1.0, 500, 1500, "load item page-5"], "isController": false}, {"data": [1.0, 500, 1500, "load item page-4"], "isController": false}, {"data": [1.0, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.99, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.54, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.52, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.87, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.82, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [1.0, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.99, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.93, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.47, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.78, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.89, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.99, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.97, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.35, 500, 1500, "Home page"], "isController": false}, {"data": [0.97, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.31, 500, 1500, "Open search"], "isController": false}, {"data": [0.91, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.9, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.9, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.94, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.98, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.97, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.97, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.88, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.46, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.78, 500, 1500, "Open search-1"], "isController": false}, {"data": [1.0, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.98, 500, 1500, "facet English language-11"], "isController": false}, {"data": [0.99, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.92, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.95, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.29, 500, 1500, "facet English language"], "isController": false}, {"data": [0.98, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.89, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.95, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.94, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.39, 500, 1500, "load item page"], "isController": false}, {"data": [0.97, 500, 1500, "Home page-12"], "isController": false}, {"data": [0.99, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.95, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.95, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.98, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.98, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.94, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.99, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.89, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.97, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.81, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.84, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.54, 500, 1500, "facet English language-2"], "isController": false}, {"data": [0.98, 500, 1500, "facet English language-3"], "isController": false}, {"data": [1.0, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.98, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 2850, 0, 0.0, 420.5719298245613, 25, 4753, 993.7000000000003, 1511.4499999999998, 2762.409999999998, 36.31637295003631, 11054.6133341616, 38.33353442728443], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 50, 0, 0.0, 1203.0800000000002, 325, 4662, 2195.1, 3037.7999999999993, 4662.0, 0.691362121652079, 1072.7401532749825, 1.6966728629996821], "isController": false}, {"data": ["load item page-5", 50, 0, 0.0, 100.37999999999998, 45, 398, 183.7, 233.14999999999998, 398.0, 0.710217184414994, 6.543999397203165, 0.4085135953324527], "isController": false}, {"data": ["load item page-4", 50, 0, 0.0, 127.80000000000001, 29, 439, 232.99999999999994, 403.4, 439.0, 0.7100961470183063, 15.044538007008649, 0.41399160133782115], "isController": false}, {"data": ["load item page-3", 50, 0, 0.0, 81.46, 29, 439, 168.0, 199.39999999999986, 439.0, 0.713368526180625, 0.6954228491938935, 0.4451586799115423], "isController": false}, {"data": ["Subject search - African-3", 50, 0, 0.0, 113.24000000000002, 25, 518, 297.7999999999999, 426.9999999999995, 518.0, 0.7041559282887603, 0.686510770945118, 0.43940980290675563], "isController": false}, {"data": ["load item page-2", 50, 0, 0.0, 920.3800000000001, 233, 2949, 2085.2, 2388.2999999999997, 2949.0, 0.7087071763688679, 850.4861094500786, 0.44363408208246513], "isController": false}, {"data": ["Subject search - African-2", 50, 0, 0.0, 992.24, 211, 4573, 2113.7999999999997, 2824.5999999999985, 4573.0, 0.693625580911424, 832.387464668447, 0.43419335680099885], "isController": false}, {"data": ["load item page-1", 50, 0, 0.0, 426.4600000000001, 66, 1501, 1131.2999999999995, 1388.0999999999997, 1501.0, 0.7101062318922912, 240.9148148797435, 0.4452033211668465], "isController": false}, {"data": ["Subject search - African-1", 50, 0, 0.0, 454.1000000000001, 77, 2222, 851.4, 1354.7999999999981, 2222.0, 0.7021091358440756, 238.2016319210408, 0.4401895168084927], "isController": false}, {"data": ["load item page-0", 50, 0, 0.0, 238.26, 138, 483, 423.6, 466.7, 483.0, 0.7123724853251269, 18.663686055664787, 0.40210087550578444], "isController": false}, {"data": ["Subject search - African-0", 50, 0, 0.0, 145.32, 65, 519, 271.8999999999999, 469.34999999999997, 519.0, 0.7021288546874122, 7.961469252899792, 0.4052325714065045], "isController": false}, {"data": ["Home page-0", 50, 0, 0.0, 265.16, 98, 681, 563.2, 635.1999999999999, 681.0, 0.6827336655970506, 12.708087086946133, 0.34176687205571105], "isController": false}, {"data": ["Home page-2", 50, 0, 0.0, 1055.5800000000002, 248, 3072, 2260.6, 2782.2999999999997, 3072.0, 0.6855607201129804, 822.7093514981215, 0.4216466225851123], "isController": false}, {"data": ["Home page-1", 50, 0, 0.0, 539.1199999999999, 118, 1931, 1187.6, 1458.95, 1931.0, 0.6852788399599797, 232.49187516275376, 0.4221424728972219], "isController": false}, {"data": ["Home page-4", 50, 0, 0.0, 351.2400000000001, 127, 1206, 637.9, 888.3999999999994, 1206.0, 0.6868509258750481, 105.9675620698596, 0.13012605431617122], "isController": false}, {"data": ["Home page-3", 50, 0, 0.0, 145.98000000000002, 29, 629, 438.79999999999984, 489.45, 629.0, 0.6871152154793316, 0.6700312766257146, 0.4212606760526605], "isController": false}, {"data": ["Home page-6", 50, 0, 0.0, 190.09999999999997, 49, 1074, 391.5, 578.5499999999996, 1074.0, 0.686954729683314, 5.803841686989077, 0.3876195730576355], "isController": false}, {"data": ["Home page", 50, 0, 0.0, 1443.98, 531, 3180, 2824.1, 3020.8499999999995, 3180.0, 0.6791079238312553, 1291.8472404025072, 5.16970907016543], "isController": false}, {"data": ["Home page-5", 50, 0, 0.0, 235.35999999999999, 53, 825, 387.2, 677.8999999999992, 825.0, 0.6866528420561132, 24.543386588983346, 0.3874492306054905], "isController": false}, {"data": ["Open search", 50, 0, 0.0, 1707.3799999999997, 798, 4753, 2981.2999999999997, 4006.7999999999993, 4753.0, 0.6867565859956597, 1289.3904128565985, 5.6106135225805565], "isController": false}, {"data": ["Home page-8", 50, 0, 0.0, 332.62, 78, 1060, 781.9999999999999, 896.8499999999996, 1060.0, 0.6873041183262769, 22.17276645491972, 0.3878167183290262], "isController": false}, {"data": ["Home page-7", 50, 0, 0.0, 347.24, 85, 1258, 741.9, 1073.3999999999992, 1258.0, 0.6855889208830386, 12.686555172768406, 0.38684890477169886], "isController": false}, {"data": ["Home page-9", 50, 0, 0.0, 292.58, 49, 1413, 677.3, 931.4499999999982, 1413.0, 0.6891513789919094, 6.342803924372528, 0.3888590495913333], "isController": false}, {"data": ["Open search-4", 50, 0, 0.0, 257.96000000000004, 49, 1431, 514.6999999999999, 928.0999999999965, 1431.0, 0.7043443962359835, 22.727900534245226, 0.4030720861272328], "isController": false}, {"data": ["Open search-3", 50, 0, 0.0, 150.04000000000005, 25, 850, 356.09999999999997, 498.3999999999997, 850.0, 0.7044734061289186, 0.6869991634378303, 0.4375440295878831], "isController": false}, {"data": ["Open search-6", 50, 0, 0.0, 203.78, 48, 1232, 458.9999999999999, 650.0499999999993, 1232.0, 0.7037693888466627, 7.7598135143076306, 0.40274302916420346], "isController": false}, {"data": ["Open search-5", 50, 0, 0.0, 175.86, 45, 872, 382.59999999999997, 691.7999999999995, 872.0, 0.7038486443875109, 6.483477043096653, 0.4027883843858217], "isController": false}, {"data": ["Open search-0", 50, 0, 0.0, 470.8999999999999, 236, 1429, 840.1999999999999, 932.3499999999999, 1429.0, 0.698236255219316, 43.49242719141449, 0.4042133321230572], "isController": false}, {"data": ["Open search-2", 50, 0, 0.0, 1081.2, 306, 3077, 2395.7, 2723.2499999999977, 3077.0, 0.6931928462498268, 831.8683902978996, 0.43189163662831004], "isController": false}, {"data": ["Open search-1", 50, 0, 0.0, 610.96, 76, 3860, 1389.0999999999997, 2157.249999999996, 3860.0, 0.7041162636774584, 238.88282933277944, 0.43938505125966404], "isController": false}, {"data": ["facet English language-13", 50, 0, 0.0, 91.82, 43, 211, 169.49999999999997, 177.14999999999998, 211.0, 0.7117843008854597, 4.850545871829001, 0.40941499338040604], "isController": false}, {"data": ["facet English language-11", 50, 0, 0.0, 133.92, 53, 621, 370.8999999999999, 488.4999999999996, 621.0, 0.7107623637113168, 8.963115986644777, 0.4088271799081695], "isController": false}, {"data": ["facet English language-12", 50, 0, 0.0, 106.22000000000001, 48, 511, 187.39999999999998, 206.7999999999999, 511.0, 0.7122912986494957, 7.985578438408171, 0.4097066161177275], "isController": false}, {"data": ["Open search-8", 50, 0, 0.0, 285.2800000000001, 54, 1489, 709.0999999999998, 1073.8499999999988, 1489.0, 0.7035020331208757, 8.967466218711747, 0.40259003067268867], "isController": false}, {"data": ["Open search-7", 50, 0, 0.0, 231.14000000000004, 47, 766, 506.79999999999995, 660.8499999999996, 766.0, 0.7042947896271464, 7.986482822250082, 0.40304369797022244], "isController": false}, {"data": ["facet English language", 50, 0, 0.0, 1493.9399999999996, 663, 3827, 2494.5, 2641.4999999999995, 3827.0, 0.7021880178636632, 1226.7395693261453, 5.790993955916636], "isController": false}, {"data": ["facet English language-10", 50, 0, 0.0, 224.14, 49, 740, 431.59999999999997, 572.2999999999989, 740.0, 0.7098642739508206, 7.602479999574081, 0.4083106028877278], "isController": false}, {"data": ["Open search-9", 50, 0, 0.0, 400.2200000000001, 85, 1910, 940.5, 1319.199999999998, 1910.0, 0.7041559282887603, 35.02406947994564, 0.40296423239962254], "isController": false}, {"data": ["Home page-10", 50, 0, 0.0, 230.83999999999997, 48, 1413, 637.9999999999994, 1014.5499999999996, 1413.0, 0.6912665385519349, 7.616434127483375, 0.39005254489776164], "isController": false}, {"data": ["Home page-11", 50, 0, 0.0, 220.40000000000003, 49, 1061, 692.0, 1012.25, 1061.0, 0.6906935945076045, 7.826462263092097, 0.38972925674462294], "isController": false}, {"data": ["load item page", 50, 0, 0.0, 1200.9000000000003, 424, 3094, 2358.6, 2829.0999999999995, 3094.0, 0.7071635669330316, 1129.2650250159113, 2.5455126051905808], "isController": false}, {"data": ["Home page-12", 50, 0, 0.0, 203.54, 57, 614, 457.9, 518.5999999999999, 614.0, 0.6930775415153447, 28.747164338214912, 0.3910744174683264], "isController": false}, {"data": ["Home page-13", 50, 0, 0.0, 121.28000000000002, 46, 971, 291.9999999999999, 348.79999999999995, 971.0, 0.6948497734789739, 14.657584545846188, 0.3920744131993663], "isController": false}, {"data": ["facet English language-8", 50, 0, 0.0, 296.34000000000003, 113, 878, 569.7999999999998, 724.6499999999996, 878.0, 0.7096325522644374, 14.97780679632836, 0.40817731765991566], "isController": false}, {"data": ["facet English language-9", 50, 0, 0.0, 300.2200000000002, 81, 685, 531.6999999999998, 660.3499999999998, 685.0, 0.7097131339512569, 25.004843237675832, 0.4082236678684476], "isController": false}, {"data": ["facet English language-4", 50, 0, 0.0, 188.25999999999996, 47, 560, 416.8999999999999, 498.5999999999997, 560.0, 0.7094311780814143, 6.537103472310902, 0.40806148817378224], "isController": false}, {"data": ["facet English language-5", 50, 0, 0.0, 203.73999999999998, 50, 883, 434.3999999999999, 495.3499999999998, 883.0, 0.7094311780814143, 7.824416226819336, 0.40806148817378224], "isController": false}, {"data": ["Open search-11", 50, 0, 0.0, 256.7599999999999, 56, 1245, 556.3, 994.3499999999993, 1245.0, 0.7051489979832739, 29.253560671901223, 0.40353253204902195], "isController": false}, {"data": ["facet English language-6", 50, 0, 0.0, 163.98000000000002, 46, 560, 213.0, 272.9499999999999, 560.0, 0.7094311780814143, 8.046806273854623, 0.40806148817378224], "isController": false}, {"data": ["Open search-10", 50, 0, 0.0, 344.1399999999999, 90, 1116, 722.8, 982.4499999999996, 1116.0, 0.7019809903547812, 31.475758183343395, 0.4017195901834978], "isController": false}, {"data": ["facet English language-7", 50, 0, 0.0, 229.80000000000007, 49, 680, 365.69999999999993, 534.6999999999999, 680.0, 0.708918190840777, 9.03869308716149, 0.40776642031759536], "isController": false}, {"data": ["facet English language-0", 50, 0, 0.0, 472.56000000000006, 244, 2378, 654.5, 699.6999999999999, 2378.0, 0.7073036171506981, 45.768456645824784, 0.4372296773988202], "isController": false}, {"data": ["facet English language-1", 50, 0, 0.0, 492.05999999999995, 79, 2146, 1166.4999999999998, 1358.6, 2146.0, 0.7055470105973161, 239.36828848406168, 0.4423449031283954], "isController": false}, {"data": ["facet English language-2", 50, 0, 0.0, 879.3399999999999, 276, 2418, 1693.2, 2157.6, 2418.0, 0.7060152499293986, 847.2558897115929, 0.44194899922338327], "isController": false}, {"data": ["facet English language-3", 50, 0, 0.0, 204.34, 29, 1222, 410.0, 771.8999999999974, 1222.0, 0.7097232079489, 0.6922435015968772, 0.44288391589779985], "isController": false}, {"data": ["Open search-13", 50, 0, 0.0, 128.39999999999998, 48, 350, 308.9, 329.04999999999995, 350.0, 0.7049998590000283, 14.877410989361552, 0.40344718493556303], "isController": false}, {"data": ["Open search-12", 50, 0, 0.0, 209.26, 55, 670, 479.79999999999984, 537.7999999999996, 670.0, 0.7038387364687003, 28.97371404263855, 0.40278271442447106], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 2850, 0, null, null, null, null, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
