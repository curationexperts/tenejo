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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.9203065134099617, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.6333333333333333, 500, 1500, "Subject search - African"], "isController": false}, {"data": [1.0, 500, 1500, "load item page-5"], "isController": false}, {"data": [1.0, 500, 1500, "load item page-4"], "isController": false}, {"data": [1.0, 500, 1500, "load item page-3"], "isController": false}, {"data": [1.0, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.8555555555555555, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.8333333333333334, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.9555555555555556, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.9333333333333333, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.9777777777777777, 500, 1500, "load item page-0"], "isController": false}, {"data": [1.0, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.9787234042553191, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.7659574468085106, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.9042553191489362, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.9574468085106383, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.9893617021276596, 500, 1500, "Home page-3"], "isController": false}, {"data": [1.0, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.5319148936170213, 500, 1500, "Home page"], "isController": false}, {"data": [0.9893617021276596, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.3804347826086957, 500, 1500, "Open search"], "isController": false}, {"data": [0.9680851063829787, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.9893617021276596, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.9787234042553191, 500, 1500, "Home page-9"], "isController": false}, {"data": [1.0, 500, 1500, "Open search-4"], "isController": false}, {"data": [1.0, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.9891304347826086, 500, 1500, "Open search-6"], "isController": false}, {"data": [1.0, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.9021739130434783, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.6847826086956522, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.9239130434782609, 500, 1500, "Open search-1"], "isController": false}, {"data": [0.9888888888888889, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.9777777777777777, 500, 1500, "facet English language-11"], "isController": false}, {"data": [1.0, 500, 1500, "facet English language-12"], "isController": false}, {"data": [1.0, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.9891304347826086, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.45555555555555555, 500, 1500, "facet English language"], "isController": false}, {"data": [0.9777777777777777, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.9891304347826086, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.9680851063829787, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.9893617021276596, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.5777777777777777, 500, 1500, "load item page"], "isController": false}, {"data": [0.9680851063829787, 500, 1500, "Home page-12"], "isController": false}, {"data": [1.0, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.9888888888888889, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.9666666666666667, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.9888888888888889, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.9888888888888889, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.9565217391304348, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.9888888888888889, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.9782608695652174, 500, 1500, "Open search-10"], "isController": false}, {"data": [1.0, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.9333333333333333, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.9444444444444444, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.7444444444444445, 500, 1500, "facet English language-2"], "isController": false}, {"data": [1.0, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.9891304347826086, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.9782608695652174, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 2610, 0, 0.0, 288.0915708812264, 25, 2817, 644.9000000000001, 912.0, 1635.6199999999926, 21.695039233940683, 6584.5775013195735, 22.994075815226427], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 45, 0, 0.0, 723.1555555555557, 309, 2014, 1290.1999999999998, 1422.0999999999997, 2014.0, 0.39330851119618226, 610.2702377713829, 0.9658591824427081], "isController": false}, {"data": ["load item page-5", 45, 0, 0.0, 121.08888888888887, 45, 430, 263.79999999999995, 341.2999999999997, 430.0, 0.39413871931192135, 3.631687220270992, 0.2267067438229704], "isController": false}, {"data": ["load item page-4", 45, 0, 0.0, 130.86666666666667, 32, 409, 207.79999999999998, 372.2999999999996, 409.0, 0.39380759436067525, 8.34351638184897, 0.2295929041341046], "isController": false}, {"data": ["load item page-3", 45, 0, 0.0, 85.17777777777775, 25, 348, 147.59999999999997, 289.5999999999992, 348.0, 0.39425612630214035, 0.38436549952251203, 0.2460250631904958], "isController": false}, {"data": ["Subject search - African-3", 45, 0, 0.0, 94.93333333333332, 27, 337, 236.99999999999994, 312.4999999999998, 337.0, 0.39484421202256753, 0.38490455737963836, 0.24639204246330143], "isController": false}, {"data": ["load item page-2", 45, 0, 0.0, 470.28888888888895, 186, 1578, 697.4, 1153.9999999999982, 1578.0, 0.39363879703983623, 472.38742579635317, 0.24640866103763187], "isController": false}, {"data": ["Subject search - African-2", 45, 0, 0.0, 537.511111111111, 194, 1733, 1098.3999999999999, 1355.2999999999997, 1733.0, 0.3935905958086975, 472.3295475976761, 0.24637848819665537], "isController": false}, {"data": ["load item page-1", 45, 0, 0.0, 301.2222222222223, 57, 1295, 508.5999999999999, 812.3999999999986, 1295.0, 0.39413526722371117, 133.7166675151523, 0.2471043374586158], "isController": false}, {"data": ["Subject search - African-1", 45, 0, 0.0, 282.3333333333334, 74, 929, 564.8, 708.7999999999995, 929.0, 0.3945672474112004, 133.8631637360915, 0.24737516878710028], "isController": false}, {"data": ["load item page-0", 45, 0, 0.0, 257.2222222222223, 136, 620, 444.5999999999999, 499.69999999999993, 620.0, 0.393800701840362, 10.317304915507872, 0.22228203678098554], "isController": false}, {"data": ["Subject search - African-0", 45, 0, 0.0, 142.08888888888885, 64, 443, 353.0, 405.5999999999999, 443.0, 0.3948303545576584, 4.476937520289893, 0.22851834974072807], "isController": false}, {"data": ["Home page-0", 47, 0, 0.0, 204.5106382978724, 89, 780, 408.0000000000002, 504.4, 780.0, 0.39242535568766285, 7.306753342921314, 0.2057770674345401], "isController": false}, {"data": ["Home page-2", 47, 0, 0.0, 564.7872340425533, 193, 2032, 1004.8000000000002, 1798.7999999999986, 2032.0, 0.3934305469521689, 472.1374772286375, 0.24444717514774572], "isController": false}, {"data": ["Home page-1", 47, 0, 0.0, 375.1276595744681, 58, 1396, 668.2000000000004, 994.9999999999993, 1396.0, 0.3935788036879171, 133.5278487751953, 0.2449236446653324], "isController": false}, {"data": ["Home page-4", 47, 0, 0.0, 329.87234042553195, 112, 1072, 501.20000000000033, 670.9999999999999, 1072.0, 0.3935063086596505, 60.71111940509382, 0.07455099988278537], "isController": false}, {"data": ["Home page-3", 47, 0, 0.0, 108.44680851063829, 27, 681, 276.6, 395.9999999999994, 681.0, 0.394156421395146, 0.38424682054141995, 0.24412834037084247], "isController": false}, {"data": ["Home page-6", 47, 0, 0.0, 114.68085106382979, 47, 425, 192.80000000000018, 400.59999999999974, 425.0, 0.3928681885432949, 3.321543478283584, 0.2241474316242174], "isController": false}, {"data": ["Home page", 47, 0, 0.0, 922.6170212765957, 391, 2817, 1440.4000000000003, 2054.3999999999987, 2817.0, 0.39105076171696246, 743.908926123647, 3.0156604909767117], "isController": false}, {"data": ["Home page-5", 47, 0, 0.0, 162.9787234042553, 51, 1237, 245.4000000000002, 394.7999999999997, 1237.0, 0.39404736952420877, 14.086964210857262, 0.22482020278767553], "isController": false}, {"data": ["Open search", 46, 0, 0.0, 1221.1739130434785, 685, 2696, 1974.2, 2167.0499999999997, 2696.0, 0.3870620308976473, 726.7183634638686, 3.1729160180572853], "isController": false}, {"data": ["Home page-8", 47, 0, 0.0, 244.14893617021272, 73, 924, 358.6000000000001, 661.1999999999991, 924.0, 0.3937106812870151, 12.703730225462191, 0.22462810832488672], "isController": false}, {"data": ["Home page-7", 47, 0, 0.0, 223.82978723404253, 82, 873, 350.6000000000002, 432.1999999999998, 873.0, 0.39351619277269834, 7.28427679102197, 0.2245171446423189], "isController": false}, {"data": ["Home page-9", 47, 0, 0.0, 180.1914893617021, 45, 981, 273.2000000000003, 545.7999999999985, 981.0, 0.39352937236251595, 3.6243901472176634, 0.22452466413942662], "isController": false}, {"data": ["Open search-4", 46, 0, 0.0, 196.84782608695656, 47, 485, 377.90000000000026, 447.9, 485.0, 0.39467700834827674, 12.736142600664087, 0.2265136345891498], "isController": false}, {"data": ["Open search-3", 46, 0, 0.0, 130.04347826086956, 26, 470, 294.50000000000017, 381.95, 470.0, 0.39428120821476326, 0.3844961637938423, 0.24553848848870297], "isController": false}, {"data": ["Open search-6", 46, 0, 0.0, 170.45652173913044, 47, 629, 301.8000000000003, 443.1499999999999, 629.0, 0.39431162619257837, 4.348360526191721, 0.22630393390137066], "isController": false}, {"data": ["Open search-5", 46, 0, 0.0, 158.58695652173913, 47, 438, 379.20000000000005, 402.54999999999995, 438.0, 0.3948938508159709, 3.6382396077459287, 0.22663808515113276], "isController": false}, {"data": ["Open search-0", 46, 0, 0.0, 399.9130434782609, 228, 796, 603.8000000000001, 649.85, 796.0, 0.39362667077407537, 24.519154403270527, 0.23030636562783455], "isController": false}, {"data": ["Open search-2", 46, 0, 0.0, 728.0652173913044, 305, 2214, 1463.4, 1862.3499999999995, 2214.0, 0.3892400511089111, 467.1087859835504, 0.24315934408820516], "isController": false}, {"data": ["Open search-1", 46, 0, 0.0, 326.9130434782609, 78, 1201, 589.3000000000003, 667.55, 1201.0, 0.3945009991166608, 133.8408039056671, 0.24683112784405206], "isController": false}, {"data": ["facet English language-13", 45, 0, 0.0, 99.26666666666667, 45, 627, 158.59999999999997, 270.99999999999955, 627.0, 0.3944150824327522, 2.6878001252267887, 0.22686570659462016], "isController": false}, {"data": ["facet English language-11", 45, 0, 0.0, 129.64444444444442, 48, 877, 229.6, 457.1999999999987, 877.0, 0.39388342801123877, 4.967102527856311, 0.22655990146349575], "isController": false}, {"data": ["facet English language-12", 45, 0, 0.0, 103.2, 47, 383, 205.4, 218.49999999999994, 383.0, 0.39425612630214035, 4.4200577941150705, 0.22677427577339912], "isController": false}, {"data": ["Open search-8", 46, 0, 0.0, 157.0, 45, 450, 252.30000000000004, 345.1999999999998, 450.0, 0.3941258118134928, 5.024459830761519, 0.22619729102764022], "isController": false}, {"data": ["Open search-7", 46, 0, 0.0, 133.06521739130437, 50, 552, 200.30000000000004, 244.84999999999997, 552.0, 0.3942237648369542, 4.470938049020868, 0.226253508377255], "isController": false}, {"data": ["facet English language", 45, 0, 0.0, 1015.1555555555557, 597, 2651, 1529.9999999999998, 1905.4999999999986, 2651.0, 0.3922970298755983, 685.351816199034, 3.2353011887689718], "isController": false}, {"data": ["facet English language-10", 45, 0, 0.0, 203.0888888888889, 51, 1320, 339.59999999999997, 638.9999999999984, 1320.0, 0.39423540233913007, 4.22213453830654, 0.22676235544701914], "isController": false}, {"data": ["Open search-9", 46, 0, 0.0, 239.60869565217394, 95, 541, 435.9000000000002, 466.65, 541.0, 0.39443334505200517, 19.619290764900576, 0.22637379097605104], "isController": false}, {"data": ["Home page-10", 47, 0, 0.0, 157.40425531914894, 42, 668, 383.4000000000002, 533.7999999999998, 668.0, 0.3942390766417541, 4.346148331404079, 0.22492957956918896], "isController": false}, {"data": ["Home page-11", 47, 0, 0.0, 140.1276595744681, 45, 623, 354.60000000000014, 427.59999999999997, 623.0, 0.3941002356216302, 4.4681343493992065, 0.2248503650667874], "isController": false}, {"data": ["load item page", 45, 0, 0.0, 760.2444444444442, 381, 1783, 1167.2, 1689.5999999999988, 1783.0, 0.3930474277229452, 627.6551513778496, 1.4148172056511485], "isController": false}, {"data": ["Home page-12", 47, 0, 0.0, 152.19148936170214, 51, 654, 298.6000000000001, 586.3999999999993, 654.0, 0.3943019178174131, 16.35715560978372, 0.2249654330399839], "isController": false}, {"data": ["Home page-13", 47, 0, 0.0, 92.46808510638299, 41, 324, 181.00000000000006, 252.2, 324.0, 0.39424569055907394, 8.318946139852367, 0.22493335308056872], "isController": false}, {"data": ["facet English language-8", 45, 0, 0.0, 216.8666666666667, 69, 502, 394.2, 455.69999999999976, 502.0, 0.39405588588141544, 8.3170334898246, 0.22665909842202508], "isController": false}, {"data": ["facet English language-9", 45, 0, 0.0, 232.88888888888889, 93, 665, 403.0, 629.6999999999996, 665.0, 0.39453957231910364, 13.900507599818512, 0.22693731259370314], "isController": false}, {"data": ["facet English language-4", 45, 0, 0.0, 155.93333333333328, 48, 501, 336.4, 380.9, 501.0, 0.3940179321938918, 3.6306768680827965, 0.22663726763886943], "isController": false}, {"data": ["facet English language-5", 45, 0, 0.0, 127.37777777777778, 44, 521, 236.59999999999994, 318.0, 521.0, 0.394650295987722, 4.352501164766498, 0.22700100032887524], "isController": false}, {"data": ["Open search-11", 46, 0, 0.0, 220.4130434782609, 57, 1016, 481.8000000000002, 731.2499999999995, 1016.0, 0.3937210058715785, 16.33445676665183, 0.2259649641799476], "isController": false}, {"data": ["facet English language-6", 45, 0, 0.0, 143.66666666666663, 45, 589, 323.19999999999993, 410.09999999999997, 589.0, 0.3946849098802789, 4.476641642547033, 0.22702091007762137], "isController": false}, {"data": ["Open search-10", 46, 0, 0.0, 227.32608695652175, 74, 1027, 362.70000000000005, 536.6999999999996, 1027.0, 0.3938828284212149, 17.661736464023942, 0.2260578376260853], "isController": false}, {"data": ["facet English language-7", 45, 0, 0.0, 184.8, 54, 470, 287.0, 382.4999999999998, 470.0, 0.3944669436701205, 5.0294107293912935, 0.22689553693525483], "isController": false}, {"data": ["facet English language-0", 45, 0, 0.0, 350.06666666666666, 230, 1002, 545.5999999999999, 587.1999999999999, 1002.0, 0.3948961861803886, 25.552988349465576, 0.24411063071502537], "isController": false}, {"data": ["facet English language-1", 45, 0, 0.0, 339.15555555555557, 62, 792, 541.3999999999999, 703.1999999999995, 792.0, 0.3932019747476954, 133.40010997367733, 0.24651920682423872], "isController": false}, {"data": ["facet English language-2", 45, 0, 0.0, 542.1111111111111, 158, 2264, 784.7999999999998, 1017.4999999999998, 2264.0, 0.39315388042879984, 471.80561960232484, 0.24610511460435613], "isController": false}, {"data": ["facet English language-3", 45, 0, 0.0, 117.44444444444444, 25, 461, 214.39999999999992, 365.2999999999999, 461.0, 0.3949031171019377, 0.38509909874333054, 0.24642880061341618], "isController": false}, {"data": ["Open search-13", 46, 0, 0.0, 123.97826086956522, 49, 704, 232.9000000000001, 268.2, 704.0, 0.3942541739517981, 8.32050065459049, 0.22627096082313414], "isController": false}, {"data": ["Open search-12", 46, 0, 0.0, 157.1304347826087, 54, 516, 304.20000000000005, 442.7999999999997, 516.0, 0.394372476230485, 16.235086786057217, 0.22633885704855067], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 2610, 0, null, null, null, null, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
