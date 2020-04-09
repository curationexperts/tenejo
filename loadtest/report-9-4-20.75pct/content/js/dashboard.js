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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.7205993930197269, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.15384615384615385, 500, 1500, "Subject search - African"], "isController": false}, {"data": [0.9127906976744186, 500, 1500, "load item page-5"], "isController": false}, {"data": [0.8546511627906976, 500, 1500, "load item page-4"], "isController": false}, {"data": [0.9302325581395349, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.945054945054945, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.19186046511627908, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.26373626373626374, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.5, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.554945054945055, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.8604651162790697, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.9065934065934066, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.8724489795918368, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.22959183673469388, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.45408163265306123, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.7346938775510204, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.9489795918367347, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.9336734693877551, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.08163265306122448, 500, 1500, "Home page"], "isController": false}, {"data": [0.8724489795918368, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.02631578947368421, 500, 1500, "Open search"], "isController": false}, {"data": [0.8214285714285714, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.8163265306122449, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.8724489795918368, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.9, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.9210526315789473, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.9157894736842105, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.9210526315789473, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.6210526315789474, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.22631578947368422, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.4842105263157895, 500, 1500, "Open search-1"], "isController": false}, {"data": [0.9772727272727273, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.9431818181818182, 500, 1500, "facet English language-11"], "isController": false}, {"data": [0.9829545454545454, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.9052631578947369, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.9105263157894737, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.03409090909090909, 500, 1500, "facet English language"], "isController": false}, {"data": [0.9034090909090909, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.7473684210526316, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.9540816326530612, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.9591836734693877, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.0872093023255814, 500, 1500, "load item page"], "isController": false}, {"data": [0.9183673469387755, 500, 1500, "Home page-12"], "isController": false}, {"data": [0.9387755102040817, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.8181818181818182, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.8011363636363636, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.9204545454545454, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.9375, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.8947368421052632, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.9090909090909091, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.8210526315789474, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.8806818181818182, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.5852272727272727, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.48863636363636365, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.19318181818181818, 500, 1500, "facet English language-2"], "isController": false}, {"data": [0.9204545454545454, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.9368421052631579, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.8947368421052632, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 5272, 0, 0.0, 975.2541729893749, 25, 15452, 2520.3999999999996, 4573.549999999993, 8591.539999999999, 41.84359448540792, 12652.268674524577, 43.95376876096291], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 91, 0, 0.0, 3343.9230769230785, 460, 15452, 6525.599999999999, 9160.999999999996, 15452.0, 0.7506640489663934, 1164.75567038785, 1.8407799533515912], "isController": false}, {"data": ["load item page-5", 86, 0, 0.0, 324.36046511627916, 56, 1254, 717.3999999999999, 1045.3499999999997, 1254.0, 0.7534408592730172, 6.942600236107339, 0.43337565049981164], "isController": false}, {"data": ["load item page-4", 86, 0, 0.0, 411.65116279069775, 36, 1836, 894.2, 984.9999999999998, 1836.0, 0.751446096849169, 15.920991122450763, 0.4380989451356972], "isController": false}, {"data": ["load item page-3", 86, 0, 0.0, 256.5697674418605, 36, 840, 545.7999999999998, 745.0499999999998, 840.0, 0.7535464876847723, 0.7348840956784986, 0.470230669561103], "isController": false}, {"data": ["Subject search - African-3", 91, 0, 0.0, 259.065934065934, 34, 1570, 500.39999999999986, 759.1999999999999, 1570.0, 0.7814713990055562, 0.7620822133674547, 0.4876564687153812], "isController": false}, {"data": ["load item page-2", 86, 0, 0.0, 2909.476744186046, 294, 13116, 6516.5999999999985, 7755.749999999998, 13116.0, 0.71216813792875, 854.639733690004, 0.44580056290266484], "isController": false}, {"data": ["Subject search - African-2", 91, 0, 0.0, 2845.7362637362626, 367, 13981, 6305.199999999999, 8836.399999999996, 13981.0, 0.7532551382761218, 903.9462521288771, 0.4715200621435489], "isController": false}, {"data": ["load item page-1", 86, 0, 0.0, 1181.2093023255811, 112, 5514, 2640.4, 3852.349999999996, 5514.0, 0.7210833018907475, 244.63915374900432, 0.45208542950572256], "isController": false}, {"data": ["Subject search - African-1", 91, 0, 0.0, 1017.7472527472526, 159, 5315, 2191.7999999999993, 2812.799999999995, 5315.0, 0.7520101810609128, 255.13141390826303, 0.47147513304795513], "isController": false}, {"data": ["load item page-0", 86, 0, 0.0, 477.29069767441854, 142, 2038, 890.2999999999995, 1422.7499999999993, 2038.0, 0.7543925823910737, 19.764958875735754, 0.4258192506074615], "isController": false}, {"data": ["Subject search - African-0", 91, 0, 0.0, 339.51648351648345, 67, 1723, 790.5999999999999, 890.5999999999998, 1723.0, 0.7850918816323009, 8.902499110301095, 0.45162329609179536], "isController": false}, {"data": ["Home page-0", 98, 0, 0.0, 445.1326530612245, 104, 2034, 920.9000000000001, 1161.05, 2034.0, 0.8218580701430703, 15.293143027938982, 0.3933538256235219], "isController": false}, {"data": ["Home page-2", 98, 0, 0.0, 2801.632653061225, 433, 9587, 6636.400000000001, 8232.949999999999, 9587.0, 0.7941395740818774, 953.0097867699791, 0.4838180133950277], "isController": false}, {"data": ["Home page-1", 98, 0, 0.0, 1313.6020408163258, 147, 5461, 2702.3000000000006, 3158.9499999999985, 5461.0, 0.814968814968815, 276.4912860576923, 0.49730379417879417], "isController": false}, {"data": ["Home page-4", 98, 0, 0.0, 643.1326530612243, 162, 2918, 1118.300000000001, 1370.7499999999993, 2918.0, 0.8161973531885832, 125.9248506978279, 0.15463113917830582], "isController": false}, {"data": ["Home page-3", 98, 0, 0.0, 261.4285714285715, 25, 1780, 501.3000000000003, 650.9999999999993, 1780.0, 0.8226307395282465, 0.8022764653110048, 0.4995691419038026], "isController": false}, {"data": ["Home page-6", 98, 0, 0.0, 293.4795918367347, 56, 1210, 548.5000000000005, 650.9999999999998, 1210.0, 0.8223615201940102, 6.943207034232897, 0.4592512786462922], "isController": false}, {"data": ["Home page", 98, 0, 0.0, 3595.4591836734676, 689, 10788, 6848.600000000004, 8364.099999999999, 10788.0, 0.7909221506625991, 1504.5044699964085, 5.948435709328039], "isController": false}, {"data": ["Home page-5", 98, 0, 0.0, 389.0, 91, 1652, 674.1, 742.3999999999994, 1652.0, 0.818535656415482, 29.252723079677764, 0.45711470879341165], "isController": false}, {"data": ["Open search", 95, 0, 0.0, 4124.652631578947, 679, 10699, 7907.6, 9593.799999999997, 10699.0, 0.7642061908745736, 1434.7894797339557, 6.221665924247056], "isController": false}, {"data": ["Home page-8", 98, 0, 0.0, 516.7346938775511, 173, 2587, 1052.4, 1218.1499999999999, 2587.0, 0.8210455764075067, 26.48261430755697, 0.4585163842577078], "isController": false}, {"data": ["Home page-7", 98, 0, 0.0, 462.94897959183675, 165, 2488, 697.3000000000001, 911.8499999999997, 2488.0, 0.8188297419015231, 15.147436352698378, 0.4572789420803288], "isController": false}, {"data": ["Home page-9", 98, 0, 0.0, 444.0510204081632, 63, 3318, 825.0000000000002, 1423.7999999999995, 3318.0, 0.8021215295966475, 7.377948231444801, 0.4479481700579492], "isController": false}, {"data": ["Open search-4", 95, 0, 0.0, 408.92631578947373, 56, 3707, 827.0000000000001, 1127.1999999999991, 3707.0, 0.7829240151640019, 25.262248962110597, 0.44671255614389316], "isController": false}, {"data": ["Open search-3", 95, 0, 0.0, 314.3157894736841, 26, 3516, 673.2, 784.3999999999983, 3516.0, 0.7841583504610026, 0.7648042776869804, 0.48570581216105785], "isController": false}, {"data": ["Open search-6", 95, 0, 0.0, 360.5578947368422, 68, 3548, 657.6000000000001, 1000.3999999999996, 3548.0, 0.7839512794910093, 8.642692155742237, 0.44729868182718413], "isController": false}, {"data": ["Open search-5", 95, 0, 0.0, 341.4736842105262, 48, 3737, 669.4000000000008, 889.1999999999998, 3737.0, 0.7827304935321744, 7.20898968546593, 0.44660213860509185], "isController": false}, {"data": ["Open search-0", 95, 0, 0.0, 696.1157894736843, 260, 2334, 1179.8, 1409.1999999999975, 2334.0, 0.8057881031748052, 50.19062587470419, 0.4613733279896859], "isController": false}, {"data": ["Open search-2", 95, 0, 0.0, 3108.747368421053, 362, 9670, 7211.8, 8828.8, 9670.0, 0.7658449284942682, 919.0548201372877, 0.4758583131459297], "isController": false}, {"data": ["Open search-1", 95, 0, 0.0, 1240.2736842105267, 103, 5656, 2860.4000000000005, 4118.2, 5656.0, 0.7791675210170187, 264.34521254100883, 0.4848972216526553], "isController": false}, {"data": ["facet English language-13", 88, 0, 0.0, 160.68181818181824, 48, 1421, 288.70000000000016, 467.9999999999997, 1421.0, 0.7386826266882676, 5.033808305038152, 0.4248867842962789], "isController": false}, {"data": ["facet English language-11", 88, 0, 0.0, 248.875, 47, 3125, 508.50000000000057, 888.799999999999, 3125.0, 0.7391169232578259, 9.320762111963615, 0.4251365896473236], "isController": false}, {"data": ["facet English language-12", 88, 0, 0.0, 171.31818181818178, 55, 2646, 257.50000000000006, 289.5, 2646.0, 0.740410422959454, 8.300785358278715, 0.4258806046124204], "isController": false}, {"data": ["Open search-8", 95, 0, 0.0, 368.7684210526316, 54, 1349, 644.4000000000001, 768.2, 1349.0, 0.7825499596368969, 9.97385182673932, 0.4464991314725119], "isController": false}, {"data": ["Open search-7", 95, 0, 0.0, 374.3368421052632, 63, 2764, 654.4000000000001, 819.9999999999974, 2764.0, 0.7823630658749702, 8.870499675216385, 0.4463924955940606], "isController": false}, {"data": ["facet English language", 88, 0, 0.0, 4310.738636363635, 873, 11757, 8697.0, 9312.049999999997, 11757.0, 0.7214356569573451, 1260.3662903168783, 5.949730588871855], "isController": false}, {"data": ["facet English language-10", 88, 0, 0.0, 385.9431818181819, 51, 3262, 789.5, 983.9499999999999, 3262.0, 0.738843877251165, 7.912898873368037, 0.42497953486419543], "isController": false}, {"data": ["Open search-9", 95, 0, 0.0, 552.7684210526317, 112, 1547, 903.2000000000002, 1009.7999999999995, 1547.0, 0.7809353138948943, 38.84173003631349, 0.4455778638747544], "isController": false}, {"data": ["Home page-10", 98, 0, 0.0, 277.3061224489797, 58, 2884, 474.8000000000002, 665.4999999999994, 2884.0, 0.8026865427143911, 8.83931039601933, 0.4482637040298141], "isController": false}, {"data": ["Home page-11", 98, 0, 0.0, 233.4081632653061, 47, 2838, 439.3000000000003, 755.8499999999998, 2838.0, 0.8031404430384934, 9.095858435740569, 0.44851718659083273], "isController": false}, {"data": ["load item page", 86, 0, 0.0, 3593.8372093023254, 462, 13280, 6955.299999999998, 8960.55, 13280.0, 0.7111787374096555, 1135.6786155634438, 2.559965650480459], "isController": false}, {"data": ["Home page-12", 98, 0, 0.0, 326.6224489795919, 58, 3022, 683.1000000000005, 1170.5499999999997, 3022.0, 0.8019902451798749, 33.259930511227864, 0.447874853718616], "isController": false}, {"data": ["Home page-13", 98, 0, 0.0, 238.92857142857144, 53, 2651, 530.5000000000003, 836.2499999999994, 2651.0, 0.802850940072912, 16.931184845164463, 0.448355512431901], "isController": false}, {"data": ["facet English language-8", 88, 0, 0.0, 525.4318181818181, 95, 3176, 930.4000000000004, 1280.4999999999995, 3176.0, 0.7392348918868971, 15.60260441167823, 0.42520444464978746], "isController": false}, {"data": ["facet English language-9", 88, 0, 0.0, 568.8636363636367, 102, 3260, 1050.9000000000012, 1628.8999999999987, 3260.0, 0.738850080601827, 26.031436745932126, 0.42498310300241804], "isController": false}, {"data": ["facet English language-4", 88, 0, 0.0, 320.8863636363636, 56, 1375, 587.0000000000002, 722.4499999999997, 1375.0, 0.7580260313030295, 6.984965256242948, 0.43601301995848085], "isController": false}, {"data": ["facet English language-5", 88, 0, 0.0, 294.9772727272728, 46, 1323, 558.3000000000001, 628.3, 1323.0, 0.758202371105597, 8.362287590251931, 0.4361144497863248], "isController": false}, {"data": ["Open search-11", 95, 0, 0.0, 362.15789473684214, 79, 2756, 665.8000000000001, 880.1999999999991, 2756.0, 0.7823888390173197, 32.45659028767202, 0.44640720096275005], "isController": false}, {"data": ["facet English language-6", 88, 0, 0.0, 403.9659090909091, 70, 3924, 674.1000000000005, 826.9999999999995, 3924.0, 0.7579999138636462, 8.597787641586631, 0.435997997329773], "isController": false}, {"data": ["Open search-10", 95, 0, 0.0, 499.8105263157894, 75, 3940, 907.6000000000005, 1129.0, 3940.0, 0.7804284963196635, 34.991941241435825, 0.4452886892292653], "isController": false}, {"data": ["facet English language-7", 88, 0, 0.0, 461.32954545454567, 162, 3855, 766.9000000000009, 1220.4999999999998, 3855.0, 0.7391045076976055, 9.423582473144469, 0.4251294482752828], "isController": false}, {"data": ["facet English language-0", 88, 0, 0.0, 711.3750000000002, 275, 1915, 1074.8000000000006, 1641.8999999999994, 1915.0, 0.7593014426727411, 49.13337240392248, 0.4693728644646925], "isController": false}, {"data": ["facet English language-1", 88, 0, 0.0, 1094.4431818181818, 180, 3888, 2397.2000000000007, 2959.1, 3888.0, 0.7573736347909907, 256.9512514012488, 0.47483776712482034], "isController": false}, {"data": ["facet English language-2", 88, 0, 0.0, 3356.8068181818176, 453, 10024, 7826.600000000002, 8644.599999999999, 10024.0, 0.7232440784391078, 867.9315957753915, 0.452733842069793], "isController": false}, {"data": ["facet English language-3", 88, 0, 0.0, 308.0340909090909, 30, 1255, 610.6000000000004, 872.8499999999998, 1255.0, 0.7580586806333236, 0.7394504397601778, 0.47304638371552127], "isController": false}, {"data": ["Open search-13", 95, 0, 0.0, 258.30526315789484, 57, 3103, 573.6000000000001, 657.7999999999993, 3103.0, 0.7823050825125992, 16.50745750333509, 0.4463594120565565], "isController": false}, {"data": ["Open search-12", 95, 0, 0.0, 374.4000000000001, 57, 3418, 695.2000000000002, 944.5999999999999, 3418.0, 0.7815585099381335, 32.17176984952942, 0.4459334405233974], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 5272, 0, null, null, null, null, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
