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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.7169896349707076, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.1513157894736842, 500, 1500, "Subject search - African"], "isController": false}, {"data": [0.9054054054054054, 500, 1500, "load item page-5"], "isController": false}, {"data": [0.8581081081081081, 500, 1500, "load item page-4"], "isController": false}, {"data": [0.9527027027027027, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.9473684210526315, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.2905405405405405, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.26973684210526316, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.5608108108108109, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.625, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.8513513513513513, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.881578947368421, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.84375, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.2625, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.59375, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.75, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.95625, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.90625, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.1, 500, 1500, "Home page"], "isController": false}, {"data": [0.81875, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.04375, 500, 1500, "Open search"], "isController": false}, {"data": [0.75625, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.78125, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.8625, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.85, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.93125, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.8625, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.86875, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.6375, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.25, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.59375, 500, 1500, "Open search-1"], "isController": false}, {"data": [0.9671052631578947, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.9013157894736842, 500, 1500, "facet English language-11"], "isController": false}, {"data": [0.9473684210526315, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.85, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.85, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.07894736842105263, 500, 1500, "facet English language"], "isController": false}, {"data": [0.868421052631579, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.74375, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.9125, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.8875, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.16891891891891891, 500, 1500, "load item page"], "isController": false}, {"data": [0.8875, 500, 1500, "Home page-12"], "isController": false}, {"data": [0.9375, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.7763157894736842, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.8026315789473685, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.875, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.8486842105263158, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.8875, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.8421052631578947, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.76875, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.8421052631578947, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.5986842105263158, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.5592105263157895, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.3223684210526316, 500, 1500, "facet English language-2"], "isController": false}, {"data": [0.9210526315789473, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.925, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.8875, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 4438, 0, 0.0, 824.3213159080667, 28, 10445, 1938.1999999999998, 3125.05, 6237.129999999989, 35.951233342784235, 10875.25875010126, 37.87491392928025], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 76, 0, 0.0, 2607.631578947368, 544, 9975, 4950.999999999997, 7472.399999999994, 9975.0, 0.6510695530750186, 1010.2215343128647, 1.5971884610771776], "isController": false}, {"data": ["load item page-5", 74, 0, 0.0, 339.44594594594594, 54, 1539, 806.5, 1240.0, 1539.0, 0.6434502847702274, 5.929064565127604, 0.37010958762662494], "isController": false}, {"data": ["load item page-4", 74, 0, 0.0, 397.31081081081066, 41, 1713, 826.5, 1149.5, 1713.0, 0.6412867331640567, 13.586991845259245, 0.3738751754872479], "isController": false}, {"data": ["load item page-3", 74, 0, 0.0, 249.43243243243245, 28, 1054, 525.0, 770.25, 1054.0, 0.6434838563813599, 0.6274935678788511, 0.4015490080348525], "isController": false}, {"data": ["Subject search - African-3", 76, 0, 0.0, 236.5526315789473, 30, 1213, 584.5999999999999, 675.2999999999995, 1213.0, 0.6592300886490987, 0.6428391267152993, 0.41137502602224035], "isController": false}, {"data": ["load item page-2", 74, 0, 0.0, 2379.7027027027034, 432, 8962, 5410.5, 7463.5, 8962.0, 0.6245938030166193, 749.5458638596521, 0.39098108177114543], "isController": false}, {"data": ["Subject search - African-2", 76, 0, 0.0, 2114.421052631578, 195, 9901, 4670.099999999998, 6589.299999999998, 9901.0, 0.6516613076098606, 782.0282271570204, 0.4079247052518757], "isController": false}, {"data": ["load item page-1", 74, 0, 0.0, 1058.9459459459458, 61, 6178, 2600.0, 3731.25, 6178.0, 0.6405484479684227, 217.31631468511418, 0.4015938511677025], "isController": false}, {"data": ["Subject search - African-1", 76, 0, 0.0, 870.157894736842, 91, 3430, 1709.7999999999997, 2412.7499999999973, 3430.0, 0.6587272695754677, 223.48382353259834, 0.41299112018305684], "isController": false}, {"data": ["load item page-0", 74, 0, 0.0, 420.6081081081081, 149, 1644, 731.0, 819.75, 1644.0, 0.6429192006950477, 16.844243796155517, 0.36289775195482193], "isController": false}, {"data": ["Subject search - African-0", 76, 0, 0.0, 353.85526315789457, 73, 2198, 748.9, 1111.6999999999994, 2198.0, 0.6593501930334447, 7.476640106493732, 0.3799329263002646], "isController": false}, {"data": ["Home page-0", 80, 0, 0.0, 420.20000000000005, 103, 1472, 796.1000000000003, 861.65, 1472.0, 0.6828385598934771, 12.70827409619915, 0.33475093463527883], "isController": false}, {"data": ["Home page-2", 80, 0, 0.0, 2187.199999999999, 334, 9722, 4723.1, 6130.55, 9722.0, 0.6718116240206246, 806.209729026356, 0.41135340650481605], "isController": false}, {"data": ["Home page-1", 80, 0, 0.0, 876.9250000000001, 174, 2814, 1913.9, 2471.55, 2814.0, 0.6806251542041365, 230.91302574305124, 0.4174146453517556], "isController": false}, {"data": ["Home page-4", 80, 0, 0.0, 589.8749999999999, 174, 1421, 1068.9, 1214.8, 1421.0, 0.6797114624841755, 104.86745593292522, 0.1287734606659473], "isController": false}, {"data": ["Home page-3", 80, 0, 0.0, 247.9625, 29, 919, 496.10000000000014, 699.1500000000002, 919.0, 0.6830309498399146, 0.6660885805763074, 0.416889007470651], "isController": false}, {"data": ["Home page-6", 80, 0, 0.0, 323.01250000000016, 48, 1045, 655.6, 850.3000000000003, 1045.0, 0.6829259964317117, 5.767948615687664, 0.38347895307444746], "isController": false}, {"data": ["Home page", 80, 0, 0.0, 2895.4750000000004, 878, 10244, 5038.500000000001, 6377.95, 10244.0, 0.6688180313341248, 1272.2564712063386, 5.062508360225391], "isController": false}, {"data": ["Home page-5", 80, 0, 0.0, 467.33749999999986, 90, 1738, 937.6000000000001, 1100.5000000000002, 1738.0, 0.6814368095128579, 24.355135518083628, 0.38264273971669266], "isController": false}, {"data": ["Open search", 80, 0, 0.0, 3140.1624999999985, 967, 10445, 4952.8, 5343.450000000001, 10445.0, 0.6617203073690827, 1242.3807656259046, 5.397964021026162], "isController": false}, {"data": ["Home page-8", 80, 0, 0.0, 550.0499999999998, 146, 1734, 958.2000000000003, 1198.6000000000001, 1734.0, 0.680619363620895, 21.95527519886847, 0.3821837246894674], "isController": false}, {"data": ["Home page-7", 80, 0, 0.0, 536.4624999999999, 172, 1886, 1023.8000000000006, 1254.9500000000003, 1886.0, 0.6801448708574926, 12.584000216264814, 0.38191728588189283], "isController": false}, {"data": ["Home page-9", 80, 0, 0.0, 406.5874999999999, 62, 1435, 713.1, 1038.8000000000006, 1435.0, 0.6816458338658692, 6.271907191789576, 0.38276011178991676], "isController": false}, {"data": ["Open search-4", 80, 0, 0.0, 427.26250000000005, 61, 1297, 846.6000000000006, 1013.9000000000003, 1297.0, 0.6736501734649196, 21.73703493139294, 0.38501344142611743], "isController": false}, {"data": ["Open search-3", 80, 0, 0.0, 277.2875000000001, 29, 1274, 595.6, 902.1500000000003, 1274.0, 0.6742974663272703, 0.6576951959466294, 0.4183080717621079], "isController": false}, {"data": ["Open search-6", 80, 0, 0.0, 376.03749999999997, 49, 1941, 746.1000000000001, 823.75, 1941.0, 0.6741383668998062, 7.432679976510491, 0.3852924601837027], "isController": false}, {"data": ["Open search-5", 80, 0, 0.0, 389.7249999999999, 65, 1289, 745.5000000000002, 894.6500000000001, 1289.0, 0.6731740154830024, 6.200662392712891, 0.38474130132951867], "isController": false}, {"data": ["Open search-0", 80, 0, 0.0, 731.9000000000001, 292, 1679, 1277.0000000000005, 1408.2, 1679.0, 0.6736842105263158, 41.96306743421053, 0.3881578947368421], "isController": false}, {"data": ["Open search-2", 80, 0, 0.0, 2117.9749999999995, 290, 9714, 4260.4000000000015, 4731.700000000001, 9714.0, 0.6634709482658527, 796.2005548923726, 0.41288756033438934], "isController": false}, {"data": ["Open search-1", 80, 0, 0.0, 911.9750000000001, 170, 4249, 2222.0000000000014, 2958.1000000000004, 4249.0, 0.668197953643767, 226.69696341877219, 0.4164817811651702], "isController": false}, {"data": ["facet English language-13", 76, 0, 0.0, 199.34210526315783, 53, 1258, 369.99999999999966, 721.2999999999981, 1258.0, 0.6514211266156958, 4.43916243635787, 0.3746943784928172], "isController": false}, {"data": ["facet English language-11", 76, 0, 0.0, 283.7763157894738, 54, 1166, 776.7999999999998, 972.05, 1166.0, 0.6510751306433651, 8.210520538850338, 0.37449536323138866], "isController": false}, {"data": ["facet English language-12", 76, 0, 0.0, 211.27631578947359, 52, 1095, 534.9, 838.699999999999, 1095.0, 0.6509803249762306, 7.298233573453707, 0.37444083145605456], "isController": false}, {"data": ["Open search-8", 80, 0, 0.0, 446.41249999999974, 141, 1352, 827.1000000000001, 1094.6000000000006, 1352.0, 0.672777731057102, 8.575444072723068, 0.38451481162223533], "isController": false}, {"data": ["Open search-7", 80, 0, 0.0, 408.20000000000016, 71, 1391, 702.5, 822.8, 1391.0, 0.6711578311534687, 7.610300594813627, 0.38358898504156985], "isController": false}, {"data": ["facet English language", 76, 0, 0.0, 3077.7236842105262, 856, 8701, 5957.999999999999, 6749.649999999993, 8701.0, 0.6455119929333424, 1127.7257254843462, 5.323582793283277], "isController": false}, {"data": ["facet English language-10", 76, 0, 0.0, 396.49999999999994, 68, 1985, 855.1999999999997, 1025.2499999999995, 1985.0, 0.6513820441397044, 6.976167438932934, 0.37467189843582605], "isController": false}, {"data": ["Open search-9", 80, 0, 0.0, 640.2624999999999, 131, 3179, 1232.6000000000004, 1431.8500000000001, 3179.0, 0.6713774987831284, 33.393269401236175, 0.38371453238557207], "isController": false}, {"data": ["Home page-10", 80, 0, 0.0, 316.9499999999999, 48, 1643, 688.1000000000004, 827.6000000000001, 1643.0, 0.6812569190155838, 7.504237897045048, 0.3825417269862897], "isController": false}, {"data": ["Home page-11", 80, 0, 0.0, 301.6500000000001, 47, 2506, 730.1000000000003, 896.7, 2506.0, 0.6809959565865078, 7.714689960629921, 0.38239519046605663], "isController": false}, {"data": ["load item page", 74, 0, 0.0, 2928.527027027026, 644, 9594, 6282.5, 7829.75, 9594.0, 0.6229323276624044, 994.7579343637672, 2.2423130466441625], "isController": false}, {"data": ["Home page-12", 80, 0, 0.0, 321.3125, 59, 1139, 766.5000000000001, 918.85, 1139.0, 0.6782304966342811, 28.129485660193804, 0.38084231988741374], "isController": false}, {"data": ["Home page-13", 80, 0, 0.0, 244.27499999999998, 49, 1197, 672.8000000000001, 754.9500000000002, 1197.0, 0.6813381481229134, 14.370778897254208, 0.3825873390338625], "isController": false}, {"data": ["facet English language-8", 76, 0, 0.0, 552.171052631579, 65, 1678, 1042.5, 1256.4999999999989, 1678.0, 0.6506682191382072, 13.733268101525645, 0.3742613096410195], "isController": false}, {"data": ["facet English language-9", 76, 0, 0.0, 528.6973684210526, 65, 1818, 957.5999999999999, 1313.249999999999, 1818.0, 0.6508019421300063, 22.929295132258368, 0.3743382264790759], "isController": false}, {"data": ["facet English language-4", 76, 0, 0.0, 398.5526315789474, 51, 1476, 932.8999999999999, 1315.3499999999992, 1476.0, 0.651527231266449, 6.003596057938774, 0.37475540939056484], "isController": false}, {"data": ["facet English language-5", 76, 0, 0.0, 442.0000000000001, 56, 1480, 856.2999999999993, 1210.0499999999988, 1480.0, 0.6509970533817584, 7.180006306533954, 0.3744504535564997], "isController": false}, {"data": ["Open search-11", 80, 0, 0.0, 409.37500000000006, 93, 1860, 801.1000000000001, 1176.8500000000004, 1860.0, 0.6736898837042838, 27.948006733214598, 0.3850361371464181], "isController": false}, {"data": ["facet English language-6", 76, 0, 0.0, 433.0263157894737, 61, 1551, 902.4999999999994, 1350.4499999999998, 1551.0, 0.651527231266449, 7.390067169992885, 0.37475540939056484], "isController": false}, {"data": ["Open search-10", 80, 0, 0.0, 536.5124999999997, 117, 1848, 950.3000000000002, 1262.5500000000002, 1848.0, 0.6722124191244433, 30.14062795405848, 0.3841917170825981], "isController": false}, {"data": ["facet English language-7", 76, 0, 0.0, 447.84210526315786, 135, 1491, 946.4999999999999, 1026.1499999999999, 1491.0, 0.6499948684615648, 8.287434572884951, 0.37387400148814615], "isController": false}, {"data": ["facet English language-0", 76, 0, 0.0, 797.8289473684208, 318, 4442, 1276.2999999999993, 1844.2999999999993, 4442.0, 0.6507852237502354, 42.11140000706445, 0.40229203772841704], "isController": false}, {"data": ["facet English language-1", 76, 0, 0.0, 934.7500000000003, 133, 2916, 2234.0999999999995, 2790.3499999999995, 2916.0, 0.6473815121469215, 219.6346676659554, 0.4058778621077379], "isController": false}, {"data": ["facet English language-2", 76, 0, 0.0, 2059.6315789473683, 339, 7874, 4889.799999999999, 5868.749999999999, 7874.0, 0.6479334333651616, 777.55468803284, 0.4055911433467467], "isController": false}, {"data": ["facet English language-3", 76, 0, 0.0, 324.48684210526324, 28, 1480, 595.0999999999998, 1058.8999999999994, 1480.0, 0.6510583982250092, 0.6350881257870525, 0.40627569967361415], "isController": false}, {"data": ["Open search-13", 80, 0, 0.0, 282.4750000000001, 57, 1213, 633.6, 1023.600000000001, 1213.0, 0.6739509532193795, 14.221788373608923, 0.385185347042619], "isController": false}, {"data": ["Open search-12", 80, 0, 0.0, 350.74999999999994, 70, 1603, 763.3000000000002, 1039.4000000000003, 1603.0, 0.6742008612916004, 27.753167361409584, 0.3853281778036221], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 4438, 0, null, null, null, null, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
