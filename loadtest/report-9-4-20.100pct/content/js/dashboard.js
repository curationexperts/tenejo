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

    var data = {"OkPercent": 99.97982650796853, "KoPercent": 0.020173492031470647};
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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.6305224934436151, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.029411764705882353, 500, 1500, "Subject search - African"], "isController": false}, {"data": [0.8205128205128205, 500, 1500, "load item page-5"], "isController": false}, {"data": [0.717948717948718, 500, 1500, "load item page-4"], "isController": false}, {"data": [0.8653846153846154, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.875, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.057692307692307696, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.08333333333333333, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.36538461538461536, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.40476190476190477, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.6602564102564102, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.8333333333333334, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.7239583333333334, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.09375, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.40625, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.5052083333333334, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.8645833333333334, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.84375, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.015625, 500, 1500, "Home page"], "isController": false}, {"data": [0.6875, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.005494505494505495, 500, 1500, "Open search"], "isController": false}, {"data": [0.671875, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.6979166666666666, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.828125, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.7692307692307693, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.8461538461538461, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.8131868131868132, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.8406593406593407, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.5, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.08791208791208792, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.31868131868131866, 500, 1500, "Open search-1"], "isController": false}, {"data": [0.9620253164556962, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.9556962025316456, 500, 1500, "facet English language-11"], "isController": false}, {"data": [0.9810126582278481, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.7967032967032966, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.8626373626373627, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.0, 500, 1500, "facet English language"], "isController": false}, {"data": [0.8544303797468354, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.6813186813186813, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.9114583333333334, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.9270833333333334, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.0, 500, 1500, "load item page"], "isController": false}, {"data": [0.9322916666666666, 500, 1500, "Home page-12"], "isController": false}, {"data": [0.9322916666666666, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.6708860759493671, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.689873417721519, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.8227848101265823, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.8417721518987342, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.8406593406593407, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.8354430379746836, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.7252747252747253, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.7974683544303798, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.45569620253164556, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.33544303797468356, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.06329113924050633, 500, 1500, "facet English language-2"], "isController": false}, {"data": [0.8544303797468354, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.9010989010989011, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.9340659340659341, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 4957, 1, 0.020173492031470647, 1360.3030058503177, 1, 16577, 3485.7999999999993, 6317.599999999986, 12087.320000000003, 39.91175452298327, 12018.907054844947, 41.69177023868952], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 85, 1, 1.1764705882352942, 5088.1529411764695, 1, 14676, 10362.2, 12907.7, 14676.0, 0.7043654082004707, 1080.0766602695442, 1.7056745697156022], "isController": false}, {"data": ["load item page-5", 78, 0, 0.0, 451.7820512820514, 70, 1782, 929.4000000000003, 1027.8499999999988, 1782.0, 0.7018048982382897, 6.466890680953195, 0.4036748877562038], "isController": false}, {"data": ["load item page-4", 78, 0, 0.0, 605.8333333333333, 65, 1915, 1321.0, 1678.6, 1915.0, 0.6992630842880964, 14.815505276410628, 0.4076758411328062], "isController": false}, {"data": ["load item page-3", 78, 0, 0.0, 400.32051282051276, 43, 1613, 678.6000000000005, 1046.9499999999994, 1613.0, 0.7050656253389739, 0.687737352320389, 0.43997747518711355], "isController": false}, {"data": ["Subject search - African-3", 84, 0, 0.0, 393.4761904761904, 50, 1519, 820.5, 1164.0, 1519.0, 0.7200226292826346, 0.7022932774315764, 0.4493109962027378], "isController": false}, {"data": ["load item page-2", 78, 0, 0.0, 5218.692307692308, 855, 13752, 12250.000000000002, 12735.55, 13752.0, 0.690552707763406, 828.7001320516055, 0.43226981023080396], "isController": false}, {"data": ["Subject search - African-2", 84, 0, 0.0, 4579.416666666667, 428, 14317, 9882.0, 12262.25, 14317.0, 0.6966676066150248, 836.038319828487, 0.4360975935939755], "isController": false}, {"data": ["load item page-1", 78, 0, 0.0, 1566.4999999999998, 319, 7030, 3215.9000000000005, 4289.749999999997, 7030.0, 0.6914832315316354, 234.59688030524995, 0.4335275728938573], "isController": false}, {"data": ["Subject search - African-1", 84, 0, 0.0, 1322.666666666667, 220, 4885, 2633.5, 3340.75, 4885.0, 0.719141140009931, 243.9802111112657, 0.4508677850452888], "isController": false}, {"data": ["load item page-0", 78, 0, 0.0, 649.769230769231, 252, 1894, 1076.4000000000003, 1246.999999999999, 1894.0, 0.7016407599309155, 18.383019534623273, 0.39604331957037997], "isController": false}, {"data": ["Subject search - African-0", 84, 0, 0.0, 473.04761904761904, 94, 1558, 952.5, 1089.0, 1558.0, 0.7209929102363827, 8.175871508227043, 0.41345443045851715], "isController": false}, {"data": ["Home page-0", 96, 0, 0.0, 610.1458333333329, 134, 2799, 988.1999999999999, 1149.8999999999992, 2799.0, 0.7979253939756633, 14.843121750635847, 0.3636378748587007], "isController": false}, {"data": ["Home page-2", 96, 0, 0.0, 4092.0312500000005, 374, 15207, 9373.8, 11328.14999999999, 15207.0, 0.7761903606859583, 931.4698621731511, 0.4681903445153257], "isController": false}, {"data": ["Home page-1", 96, 0, 0.0, 1600.7187500000007, 195, 7615, 3541.799999999999, 5088.399999999987, 7615.0, 0.7914392652805488, 268.5085717355191, 0.47816122277366485], "isController": false}, {"data": ["Home page-4", 96, 0, 0.0, 1049.4166666666665, 155, 6358, 2058.7999999999993, 2348.349999999999, 6358.0, 0.7947151442904683, 122.61047044963493, 0.15056126757065513], "isController": false}, {"data": ["Home page-3", 96, 0, 0.0, 428.9270833333334, 50, 1607, 864.5, 1241.4999999999995, 1607.0, 0.7981708584493868, 0.7785787128455622, 0.4798898357929744], "isController": false}, {"data": ["Home page-6", 96, 0, 0.0, 467.90624999999994, 45, 1421, 875.5999999999997, 1216.549999999999, 1421.0, 0.7983500765085491, 6.735762042300079, 0.4410156509879582], "isController": false}, {"data": ["Home page", 96, 0, 0.0, 4953.031250000002, 720, 15582, 9896.4, 12300.049999999994, 15582.0, 0.772953083358159, 1470.2772475397346, 5.739528901198883], "isController": false}, {"data": ["Home page-5", 96, 0, 0.0, 647.3437499999995, 99, 2243, 1162.5, 1581.6999999999987, 2243.0, 0.7932638676571447, 28.344867980441087, 0.4382059841843016], "isController": false}, {"data": ["Open search", 91, 0, 0.0, 5442.285714285712, 1246, 16577, 11127.8, 12033.199999999999, 16577.0, 0.7500638790666238, 1408.223159651818, 6.083772759493254], "isController": false}, {"data": ["Home page-8", 96, 0, 0.0, 724.7395833333334, 168, 2978, 1208.8, 1822.0499999999997, 2978.0, 0.7957361803005562, 25.66144760522782, 0.4395717115787903], "isController": false}, {"data": ["Home page-7", 96, 0, 0.0, 649.7500000000002, 139, 1998, 1328.6999999999998, 1504.2499999999998, 1998.0, 0.7982571385807654, 14.762040378506926, 0.4409643112537626], "isController": false}, {"data": ["Home page-9", 96, 0, 0.0, 466.1458333333331, 80, 1783, 876.3999999999996, 1161.7499999999995, 1783.0, 0.7977529957286975, 7.332926320031911, 0.44068581827851555], "isController": false}, {"data": ["Open search-4", 91, 0, 0.0, 559.4505494505491, 64, 2171, 1141.3999999999999, 1302.5999999999985, 2171.0, 0.7650080283809572, 24.682862861277144, 0.4351032419316873], "isController": false}, {"data": ["Open search-3", 91, 0, 0.0, 429.9450549450551, 26, 2172, 1006.7999999999995, 1346.7999999999972, 2172.0, 0.7652396209120648, 0.7463681338664783, 0.47260017753979666], "isController": false}, {"data": ["Open search-6", 91, 0, 0.0, 501.02197802197776, 51, 1928, 972.4, 1296.1999999999978, 1928.0, 0.7665998348861894, 8.450055309967482, 0.43600859213097903], "isController": false}, {"data": ["Open search-5", 91, 0, 0.0, 473.25274725274716, 52, 1550, 965.9999999999997, 1184.0, 1550.0, 0.766554631758948, 7.058679599117199, 0.43598288256130335], "isController": false}, {"data": ["Open search-0", 91, 0, 0.0, 905.4175824175824, 283, 2974, 1559.6, 1761.3999999999999, 2974.0, 0.7669875090605667, 47.77289985808624, 0.4339655888104108], "isController": false}, {"data": ["Open search-2", 91, 0, 0.0, 4306.956043956045, 325, 15714, 10633.0, 11397.0, 15714.0, 0.7518610626853833, 902.2735212194195, 0.4658062651301711], "isController": false}, {"data": ["Open search-1", 91, 0, 0.0, 1644.9010989010994, 86, 4553, 3317.2, 3876.3999999999996, 4553.0, 0.7616209973050334, 258.3923712750665, 0.47259668297316754], "isController": false}, {"data": ["facet English language-13", 79, 0, 0.0, 227.96202531645568, 61, 1562, 401.0, 617.0, 1562.0, 0.6908311835949456, 4.707747734576538, 0.3973628585326396], "isController": false}, {"data": ["facet English language-11", 79, 0, 0.0, 238.92405063291133, 53, 1939, 481.0, 703.0, 1939.0, 0.6917082567200771, 8.722821105310393, 0.39786734688293496], "isController": false}, {"data": ["facet English language-12", 79, 0, 0.0, 206.0, 71, 967, 404.0, 497.0, 967.0, 0.6911515109096954, 7.748541828883134, 0.3975471093025494], "isController": false}, {"data": ["Open search-8", 91, 0, 0.0, 485.945054945055, 63, 2066, 839.9999999999999, 1122.599999999999, 2066.0, 0.7653168495858038, 9.75276349817081, 0.43527888598040454], "isController": false}, {"data": ["Open search-7", 91, 0, 0.0, 431.6263736263737, 94, 1456, 816.7999999999996, 1007.5999999999984, 1456.0, 0.7651173740499092, 8.673618322038744, 0.4351654329849667], "isController": false}, {"data": ["facet English language", 79, 0, 0.0, 5522.772151898734, 1794, 14983, 11041.0, 12649.0, 14983.0, 0.6656162848500679, 1162.8485747306993, 5.48913746082132], "isController": false}, {"data": ["facet English language-10", 79, 0, 0.0, 393.9493670886074, 78, 1166, 790.0, 884.0, 1166.0, 0.6898418603026572, 7.388025881622263, 0.3967938044123682], "isController": false}, {"data": ["Open search-9", 91, 0, 0.0, 695.9010989010991, 139, 2356, 1246.2, 1448.3999999999992, 2356.0, 0.762341981586509, 37.91548554272885, 0.4335869106510065], "isController": false}, {"data": ["Home page-10", 96, 0, 0.0, 333.13541666666663, 64, 2364, 664.6, 780.6999999999985, 2364.0, 0.7977529957286975, 8.780111475074374, 0.44068581827851555], "isController": false}, {"data": ["Home page-11", 96, 0, 0.0, 276.64583333333314, 50, 1384, 615.3999999999999, 764.899999999999, 1384.0, 0.7987419813793276, 9.041228814616979, 0.44123214270856737], "isController": false}, {"data": ["load item page", 78, 0, 0.0, 6070.0, 1550, 14459, 12930.2, 13824.65, 14459.0, 0.6866499405783705, 1096.5092543685903, 2.4716715634490956], "isController": false}, {"data": ["Home page-12", 96, 0, 0.0, 307.1770833333335, 54, 984, 568.3, 777.9999999999998, 984.0, 0.7976601967561818, 33.075488333181, 0.4406345553044403], "isController": false}, {"data": ["Home page-13", 96, 0, 0.0, 250.28125, 69, 1097, 604.5999999999999, 796.0999999999993, 1097.0, 0.798204040907957, 16.82842023416064, 0.4409349796291677], "isController": false}, {"data": ["facet English language-8", 79, 0, 0.0, 648.0632911392405, 213, 1527, 1137.0, 1421.0, 1527.0, 0.6874227737073841, 14.509042682210543, 0.3954023571422356], "isController": false}, {"data": ["facet English language-9", 79, 0, 0.0, 688.5569620253164, 184, 4516, 1253.0, 1514.0, 4516.0, 0.6835684001038331, 24.0837280030501, 0.3931853395128494], "isController": false}, {"data": ["facet English language-4", 79, 0, 0.0, 456.06329113924045, 50, 1586, 832.0, 971.0, 1586.0, 0.6876082547806182, 6.3361261298752725, 0.3955090449861173], "isController": false}, {"data": ["facet English language-5", 79, 0, 0.0, 451.02531645569627, 107, 1470, 788.0, 1015.0, 1470.0, 0.6876082547806182, 7.583810075963304, 0.3955090449861173], "isController": false}, {"data": ["Open search-11", 91, 0, 0.0, 462.25274725274716, 67, 1393, 1065.2, 1201.2, 1393.0, 0.7604181464180964, 31.54379050166707, 0.4324927170116402], "isController": false}, {"data": ["facet English language-6", 79, 0, 0.0, 487.8101265822783, 88, 3507, 950.0, 1710.0, 3507.0, 0.6875663632091072, 7.798824487262616, 0.39548494915055094], "isController": false}, {"data": ["Open search-10", 91, 0, 0.0, 556.8351648351652, 123, 1770, 968.8, 1283.399999999999, 1770.0, 0.7628596338273758, 34.202781883445944, 0.43388132869609686], "isController": false}, {"data": ["facet English language-7", 79, 0, 0.0, 532.0506329113924, 159, 2575, 1007.0, 1209.0, 2575.0, 0.688267221926974, 8.775407079568918, 0.3958880797997926], "isController": false}, {"data": ["facet English language-0", 79, 0, 0.0, 965.6329113924048, 350, 2639, 1677.0, 1864.0, 2639.0, 0.6843737546996552, 44.28499524078694, 0.4228014628489007], "isController": false}, {"data": ["facet English language-1", 79, 0, 0.0, 1578.860759493671, 178, 4429, 3281.0, 4000.0, 4429.0, 0.68741679211298, 233.21732948365428, 0.43097810599270814], "isController": false}, {"data": ["facet English language-2", 79, 0, 0.0, 4428.670886075949, 956, 13904, 9547.0, 12148.0, 13904.0, 0.6699570888244373, 803.9843249784808, 0.4193774354848284], "isController": false}, {"data": ["facet English language-3", 79, 0, 0.0, 442.0000000000001, 88, 1372, 810.0, 1069.0, 1372.0, 0.6876082547806182, 0.6707699444473457, 0.4290836668015771], "isController": false}, {"data": ["Open search-13", 91, 0, 0.0, 290.8681318681318, 63, 1234, 641.0, 855.1999999999995, 1234.0, 0.764429659870803, 16.12892931808254, 0.4347742911174953], "isController": false}, {"data": ["Open search-12", 91, 0, 0.0, 311.7032967032966, 72, 1186, 617.5999999999999, 851.9999999999986, 1186.0, 0.7626806128264441, 31.393231785762175, 0.43377950934912335], "isController": false}]}, function(index, item){
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
    createTable($("#errorsTable"), {"supportsControllersDiscrimination": false, "titles": ["Type of error", "Number of errors", "% in errors", "% in all samples"], "items": [{"data": ["Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, 100.0, 0.020173492031470647], "isController": false}]}, function(index, item){
        switch(index){
            case 2:
            case 3:
                item = item.toFixed(2) + '%';
                break;
        }
        return item;
    }, [[1, 1]]);

        // Create top5 errors by sampler
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 4957, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": ["Subject search - African", 85, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
