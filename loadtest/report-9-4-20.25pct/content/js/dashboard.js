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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.8276983094928478, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.3939393939393939, 500, 1500, "Subject search - African"], "isController": false}, {"data": [0.9846153846153847, 500, 1500, "load item page-5"], "isController": false}, {"data": [0.9692307692307692, 500, 1500, "load item page-4"], "isController": false}, {"data": [0.9846153846153847, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.9924242424242424, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.4461538461538462, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.4621212121212121, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.7461538461538462, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.7954545454545454, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.9384615384615385, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.9696969696969697, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.9492753623188406, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.45652173913043476, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.6884057971014492, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.8188405797101449, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.9855072463768116, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.9782608695652174, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.30434782608695654, 500, 1500, "Home page"], "isController": false}, {"data": [0.927536231884058, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.2318840579710145, 500, 1500, "Open search"], "isController": false}, {"data": [0.855072463768116, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.9202898550724637, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.9420289855072463, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.9420289855072463, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.9782608695652174, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.9565217391304348, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.9710144927536232, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.8333333333333334, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.42028985507246375, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.717391304347826, 500, 1500, "Open search-1"], "isController": false}, {"data": [1.0, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.9696969696969697, 500, 1500, "facet English language-11"], "isController": false}, {"data": [0.9848484848484849, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.9855072463768116, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.9637681159420289, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.22727272727272727, 500, 1500, "facet English language"], "isController": false}, {"data": [0.9545454545454546, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.8768115942028986, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.9492753623188406, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.9855072463768116, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.3153846153846154, 500, 1500, "load item page"], "isController": false}, {"data": [0.9710144927536232, 500, 1500, "Home page-12"], "isController": false}, {"data": [0.9927536231884058, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.9015151515151515, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.9621212121212122, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.9545454545454546, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.946969696969697, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.9492753623188406, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.9696969696969697, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.8695652173913043, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.9545454545454546, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.7727272727272727, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.7348484848484849, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.44696969696969696, 500, 1500, "facet English language-2"], "isController": false}, {"data": [1.0, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.9855072463768116, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.9637681159420289, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 3845, 0, 0.0, 491.8754226267878, 30, 6499, 1145.2000000000003, 1618.199999999999, 3149.5599999999995, 31.667462814409728, 9591.93958963045, 33.49559991105108], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 66, 0, 0.0, 1356.1060606060612, 416, 4627, 2868.0, 3900.149999999999, 4627.0, 0.5736337088026701, 890.0689782991543, 1.4081627913798498], "isController": false}, {"data": ["load item page-5", 65, 0, 0.0, 189.96923076923076, 51, 889, 405.4, 486.2, 889.0, 0.5772082656223637, 5.318511082953708, 0.3320074887222385], "isController": false}, {"data": ["load item page-4", 65, 0, 0.0, 209.49230769230778, 31, 682, 418.2, 541.5, 682.0, 0.57693161141437, 12.223348463919583, 0.3363556367327919], "isController": false}, {"data": ["load item page-3", 65, 0, 0.0, 152.41538461538465, 34, 884, 284.7999999999999, 357.9, 884.0, 0.5772082656223637, 0.5627346989858895, 0.36019148606708046], "isController": false}, {"data": ["Subject search - African-3", 66, 0, 0.0, 134.01515151515156, 32, 520, 293.30000000000007, 357.75, 520.0, 0.5787950539331755, 0.564313187867228, 0.36118167916337807], "isController": false}, {"data": ["load item page-2", 65, 0, 0.0, 1198.0461538461536, 227, 4936, 2689.0, 2980.1, 4936.0, 0.5644173910023185, 677.3308284371934, 0.35331205823484974], "isController": false}, {"data": ["Subject search - African-2", 66, 0, 0.0, 1139.5757575757577, 344, 4551, 2413.200000000002, 3766.5999999999995, 4551.0, 0.5740478199229384, 688.8878343312125, 0.35934048102598004], "isController": false}, {"data": ["load item page-1", 65, 0, 0.0, 623.2615384615387, 126, 2729, 1282.0, 1759.7999999999993, 2729.0, 0.5768394522687539, 195.70194462840445, 0.3616512972231836], "isController": false}, {"data": ["Subject search - African-1", 66, 0, 0.0, 474.3636363636364, 84, 1942, 875.1000000000001, 1061.35, 1942.0, 0.5773823583444873, 195.8861660745217, 0.36199167388394615], "isController": false}, {"data": ["load item page-0", 65, 0, 0.0, 275.5538461538462, 149, 703, 512.4, 611.8, 703.0, 0.5766603381891091, 15.10811965480225, 0.32549772995439946], "isController": false}, {"data": ["Subject search - African-0", 66, 0, 0.0, 182.78787878787873, 67, 883, 375.10000000000025, 623.4499999999999, 883.0, 0.578642819568648, 6.561239698404348, 0.3343737670962651], "isController": false}, {"data": ["Home page-0", 69, 0, 0.0, 272.15942028985506, 99, 704, 505.0, 564.0, 704.0, 0.5838897210022594, 10.870037334035693, 0.2989443310866272], "isController": false}, {"data": ["Home page-2", 69, 0, 0.0, 1218.2608695652177, 234, 6084, 2614.0, 3372.5, 6084.0, 0.5812826971517148, 697.5702192394042, 0.35926225800948586], "isController": false}, {"data": ["Home page-1", 69, 0, 0.0, 650.1884057971015, 105, 2492, 1379.0, 1549.5, 2492.0, 0.5841863300398771, 198.1946132226131, 0.3616273452117887], "isController": false}, {"data": ["Home page-4", 69, 0, 0.0, 462.47826086956525, 153, 1453, 825.0, 919.5, 1453.0, 0.5848101909532406, 90.22590942222449, 0.11079411820793816], "isController": false}, {"data": ["Home page-3", 69, 0, 0.0, 198.21739130434779, 31, 1008, 328.0, 468.0, 1008.0, 0.5858877473040672, 0.5713599600917042, 0.3609641011080921], "isController": false}, {"data": ["Home page-6", 69, 0, 0.0, 217.20289855072465, 52, 760, 363.0, 519.0, 760.0, 0.5855943782939683, 4.949257106696994, 0.3321898816293103], "isController": false}, {"data": ["Home page", 69, 0, 0.0, 1688.3478260869565, 569, 6499, 2750.0, 3587.5, 6499.0, 0.5783544558438947, 1100.2056966211317, 4.4302200156742435], "isController": false}, {"data": ["Home page-5", 69, 0, 0.0, 316.65217391304367, 68, 1001, 535.0, 733.5, 1001.0, 0.5846763943260969, 20.900170279055875, 0.3316691372421916], "isController": false}, {"data": ["Open search", 69, 0, 0.0, 1762.9710144927542, 819, 4075, 3080.0, 3314.0, 4075.0, 0.5763977645791043, 1082.195907105982, 4.716793040832352], "isController": false}, {"data": ["Home page-8", 69, 0, 0.0, 408.9565217391303, 158, 1023, 704.0, 861.5, 1023.0, 0.584117094313747, 18.845687864015, 0.3313518633546945], "isController": false}, {"data": ["Home page-7", 69, 0, 0.0, 366.9855072463769, 154, 1010, 611.0, 750.5, 1010.0, 0.5860420081706146, 10.846272661352652, 0.33244380844495025], "isController": false}, {"data": ["Home page-9", 69, 0, 0.0, 305.28985507246375, 61, 2174, 505.0, 656.5, 2174.0, 0.585395651104192, 5.389648346363336, 0.33207714973826874], "isController": false}, {"data": ["Open search-4", 69, 0, 0.0, 289.3478260869567, 51, 818, 521.0, 606.0, 818.0, 0.5830263291310372, 18.81367278597864, 0.33411626886385914], "isController": false}, {"data": ["Open search-3", 69, 0, 0.0, 225.6811594202899, 30, 1093, 449.0, 601.5, 1093.0, 0.5837316526373673, 0.5692573283702043, 0.36302299236495916], "isController": false}, {"data": ["Open search-6", 69, 0, 0.0, 243.39130434782615, 46, 747, 471.0, 644.0, 747.0, 0.5834355050099354, 6.43349614742316, 0.3343507562465649], "isController": false}, {"data": ["Open search-5", 69, 0, 0.0, 225.20289855072463, 50, 759, 405.0, 658.5, 759.0, 0.5834305717619602, 5.374743494009267, 0.33434792913855205], "isController": false}, {"data": ["Open search-0", 69, 0, 0.0, 434.81159420289845, 240, 842, 648.0, 707.5, 842.0, 0.5823521964805671, 36.274394899670845, 0.3388812402413808], "isController": false}, {"data": ["Open search-2", 69, 0, 0.0, 1184.2898550724651, 419, 3808, 2692.0, 2804.5, 3808.0, 0.5792186424458137, 695.0932107862683, 0.3613476355917264], "isController": false}, {"data": ["Open search-1", 69, 0, 0.0, 602.1884057971013, 130, 2150, 1200.0, 1455.0, 2150.0, 0.5821654868675278, 197.50900965688095, 0.36375455607772333], "isController": false}, {"data": ["facet English language-13", 66, 0, 0.0, 127.19696969696973, 51, 459, 221.50000000000003, 323.9, 459.0, 0.5754793481388475, 3.921645162485722, 0.33101302349002065], "isController": false}, {"data": ["facet English language-11", 66, 0, 0.0, 177.80303030303028, 53, 848, 347.60000000000036, 516.75, 848.0, 0.5760972033099403, 7.264967275387557, 0.33136841088823715], "isController": false}, {"data": ["facet English language-12", 66, 0, 0.0, 151.4393939393939, 46, 832, 270.7000000000003, 415.7499999999999, 832.0, 0.5757052389176742, 6.4542721172214375, 0.33114295480713873], "isController": false}, {"data": ["Open search-8", 69, 0, 0.0, 270.26086956521743, 91, 640, 423.0, 484.5, 640.0, 0.5826275658833563, 7.42719035508617, 0.3338877486722002], "isController": false}, {"data": ["Open search-7", 69, 0, 0.0, 254.97101449275357, 48, 964, 446.0, 786.0, 964.0, 0.582957368074213, 6.610991993840929, 0.3340767491889289], "isController": false}, {"data": ["facet English language", 66, 0, 0.0, 1844.4393939393938, 902, 5138, 2987.200000000002, 4687.75, 5138.0, 0.5714483618480294, 998.334383265979, 4.712774820123641], "isController": false}, {"data": ["facet English language-10", 66, 0, 0.0, 264.1969696969697, 48, 972, 443.5000000000004, 627.15, 972.0, 0.5767516647150323, 6.176902461244036, 0.33174485402065823], "isController": false}, {"data": ["Open search-9", 69, 0, 0.0, 437.89855072463786, 128, 1181, 777.0, 1059.5, 1181.0, 0.5825193539944786, 28.974443084587723, 0.33382573543068444], "isController": false}, {"data": ["Home page-10", 69, 0, 0.0, 244.14492753623188, 53, 794, 520.0, 606.5, 794.0, 0.5865202349481057, 6.464091175208044, 0.33271509195192234], "isController": false}, {"data": ["Home page-11", 69, 0, 0.0, 192.56521739130434, 52, 706, 397.0, 461.5, 706.0, 0.5859375, 6.641205497409986, 0.33238452413807745], "isController": false}, {"data": ["load item page", 65, 0, 0.0, 1546.7538461538459, 554, 5093, 2978.3999999999996, 3322.799999999999, 5093.0, 0.5633265734144524, 899.5729635879786, 2.0277556148492883], "isController": false}, {"data": ["Home page-12", 69, 0, 0.0, 203.18840579710138, 68, 750, 338.0, 512.5, 750.0, 0.5858529254438473, 24.30146225759274, 0.33233654756446507], "isController": false}, {"data": ["Home page-13", 69, 0, 0.0, 154.65217391304344, 46, 1081, 275.0, 359.5, 1081.0, 0.5854204846263491, 12.351033288366253, 0.332091237040148], "isController": false}, {"data": ["facet English language-8", 66, 0, 0.0, 369.4090909090908, 175, 1273, 601.0, 717.9999999999999, 1273.0, 0.5755847417717544, 12.148547874914971, 0.33107364541363615], "isController": false}, {"data": ["facet English language-9", 66, 0, 0.0, 361.57575757575756, 106, 1066, 499.3, 681.9999999999998, 1066.0, 0.5751984870536765, 20.265618736001326, 0.33085147351036664], "isController": false}, {"data": ["facet English language-4", 66, 0, 0.0, 225.12121212121212, 50, 2217, 324.20000000000016, 557.9499999999999, 2217.0, 0.5742076369615716, 5.291063730522616, 0.3302815411819977], "isController": false}, {"data": ["facet English language-5", 66, 0, 0.0, 235.7727272727273, 57, 957, 526.6000000000001, 586.4, 957.0, 0.5769281200010489, 6.363000537045778, 0.33184635027404086], "isController": false}, {"data": ["Open search-11", 69, 0, 0.0, 277.3913043478261, 86, 932, 528.0, 672.0, 932.0, 0.582755504505798, 24.1764438110732, 0.33396106675928816], "isController": false}, {"data": ["facet English language-6", 66, 0, 0.0, 225.93939393939397, 50, 864, 393.8000000000004, 544.9999999999999, 864.0, 0.5766710353866318, 6.540972108453473, 0.3316984764089122], "isController": false}, {"data": ["Open search-10", 69, 0, 0.0, 413.6231884057971, 103, 1199, 745.0, 946.5, 1199.0, 0.5823177936063194, 26.110758664087026, 0.3337102267452655], "isController": false}, {"data": ["facet English language-7", 66, 0, 0.0, 304.39393939393943, 142, 1299, 505.20000000000016, 748.3499999999999, 1299.0, 0.5765954658629275, 7.351592189752326, 0.3316550091731097], "isController": false}, {"data": ["facet English language-0", 66, 0, 0.0, 499.9696969696969, 253, 1159, 747.8000000000001, 811.9, 1159.0, 0.5760318388507292, 37.27409433175943, 0.3560821816333121], "isController": false}, {"data": ["facet English language-1", 66, 0, 0.0, 530.6666666666667, 116, 1695, 934.1, 1361.7499999999995, 1695.0, 0.5747927262593187, 195.00774520951632, 0.36036809595554936], "isController": false}, {"data": ["facet English language-2", 66, 0, 0.0, 1208.1818181818185, 367, 4663, 2476.800000000001, 4041.5499999999997, 4663.0, 0.5730211236423306, 687.6560071714462, 0.3586977932175136], "isController": false}, {"data": ["facet English language-3", 66, 0, 0.0, 158.59090909090907, 31, 445, 274.6, 315.5, 445.0, 0.5773520535362814, 0.5631027752263482, 0.3602812130953943], "isController": false}, {"data": ["Open search-13", 69, 0, 0.0, 166.20289855072468, 50, 889, 329.0, 404.5, 889.0, 0.5829524429086792, 12.302395490989582, 0.3340739267127396], "isController": false}, {"data": ["Open search-12", 69, 0, 0.0, 231.78260869565216, 54, 815, 470.0, 618.0, 815.0, 0.581939630088809, 23.956201794946402, 0.33349351168939606], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 3845, 0, null, null, null, null, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
