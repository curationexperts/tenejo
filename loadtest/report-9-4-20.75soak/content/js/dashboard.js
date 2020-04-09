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

    var data = {"OkPercent": 99.97759982079856, "KoPercent": 0.022400179201433612};
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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.7099456795654365, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.0, 500, 1500, "Subject search - African"], "isController": false}, {"data": [0.9539579967689822, 500, 1500, "load item page-5"], "isController": false}, {"data": [0.9458804523424879, 500, 1500, "load item page-4"], "isController": false}, {"data": [0.9652665589660743, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.9776714513556619, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.0024232633279483036, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.007974481658692184, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.33521809369951533, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.3580542264752791, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.8683360258481422, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.9465709728867624, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.927892234548336, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.00792393026941363, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.312202852614897, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.881933438985737, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.9683042789223455, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.9421553090332805, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.001584786053882726, 500, 1500, "Home page"], "isController": false}, {"data": [0.8882725832012678, 500, 1500, "Home page-5"], "isController": false}, {"data": [0.002380952380952381, 500, 1500, "Open search"], "isController": false}, {"data": [0.9001584786053882, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.9374009508716323, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.9675118858954042, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.903968253968254, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.9817460317460317, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.9531746031746032, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.9523809523809523, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.5007936507936508, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.00873015873015873, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.2992063492063492, 500, 1500, "Open search-1"], "isController": false}, {"data": [0.9887459807073955, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.9855305466237942, 500, 1500, "facet English language-11"], "isController": false}, {"data": [0.9871382636655949, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.942063492063492, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.9547619047619048, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.0, 500, 1500, "facet English language"], "isController": false}, {"data": [0.957395498392283, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.8277777777777777, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.9635499207606973, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.9881141045958796, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.0, 500, 1500, "load item page"], "isController": false}, {"data": [0.9770206022187005, 500, 1500, "Home page-12"], "isController": false}, {"data": [0.9841521394611727, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.932475884244373, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.8914790996784566, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.9421221864951769, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.9590032154340836, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.9515873015873015, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.9533762057877814, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.8849206349206349, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.9485530546623794, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.4959807073954984, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.3360128617363344, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.0040192926045016075, 500, 1500, "facet English language-2"], "isController": false}, {"data": [0.9670418006430869, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.9793650793650793, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.9523809523809523, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 35714, 8, 0.022400179201433612, 1043.0350282802283, 0, 10747, 3720.9000000000015, 4510.9000000000015, 5749.960000000006, 39.542461588540945, 12023.479758409097, 41.96843356633388], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 627, 0, 0.0, 3912.574162679427, 1851, 9559, 5312.000000000001, 5623.200000000001, 7310.600000000006, 0.6975083267142352, 1082.2781527470231, 1.713310884717559], "isController": false}, {"data": ["load item page-5", 619, 0, 0.0, 268.0743134087238, 53, 2867, 482.0, 556.0, 961.7999999999993, 0.7013862292615163, 6.463130208345136, 0.40343407132327447], "isController": false}, {"data": ["load item page-4", 619, 0, 0.0, 308.0032310177708, 65, 3026, 524.0, 620.0, 1016.9999999999966, 0.7013218614147214, 14.859182807431631, 0.40887612428182485], "isController": false}, {"data": ["load item page-3", 619, 0, 0.0, 219.6720516962843, 30, 1978, 439.0, 551.0, 834.7999999999984, 0.7015094352452392, 0.6842565724719311, 0.43775832922041785], "isController": false}, {"data": ["Subject search - African-3", 627, 0, 0.0, 193.03349282296656, 25, 1101, 306.20000000000005, 486.60000000000014, 690.840000000002, 0.6997736617247244, 0.6825411162366463, 0.43667516586142474], "isController": false}, {"data": ["load item page-2", 619, 0, 0.0, 3644.3586429725356, 696, 7320, 5044.0, 5435.0, 6693.999999999997, 0.6986156349953389, 838.3760946200953, 0.43731701370313686], "isController": false}, {"data": ["Subject search - African-2", 627, 0, 0.0, 3590.609250398722, 683, 9127, 4944.2, 5297.0, 6870.560000000007, 0.6977699184377076, 837.3611593838091, 0.4367876149595416], "isController": false}, {"data": ["load item page-1", 619, 0, 0.0, 1397.953150242324, 264, 4085, 1997.0, 2283.0, 3227.599999999996, 0.7004306686793204, 237.6324695955522, 0.4391371965743396], "isController": false}, {"data": ["Subject search - African-1", 627, 0, 0.0, 1348.6953748006388, 218, 4056, 1860.2, 2148.4, 2969.0800000000017, 0.6987715217728068, 237.06951948626642, 0.4380969892364667], "isController": false}, {"data": ["load item page-0", 619, 0, 0.0, 473.0710823909533, 222, 3294, 643.0, 775.0, 1440.1999999999994, 0.7002745664576402, 18.34732488964171, 0.3952721673950352], "isController": false}, {"data": ["Subject search - African-0", 627, 0, 0.0, 317.33173843700155, 84, 1528, 515.4000000000001, 632.6, 1237.2400000000005, 0.6995519297368703, 7.932799772157498, 0.4053044682624335], "isController": false}, {"data": ["Home page-0", 631, 0, 0.0, 396.1125198098259, 101, 4559, 564.0000000000003, 738.1999999999999, 1554.8799999999978, 0.7009109620919359, 13.052633425094168, 0.3729891939884944], "isController": false}, {"data": ["Home page-2", 631, 1, 0.15847860538827258, 3638.8716323296358, 1, 10276, 5013.800000000001, 5499.599999999999, 7062.919999999998, 0.6991434108226513, 837.6820973062758, 0.4351360109547241], "isController": false}, {"data": ["Home page-1", 631, 0, 0.0, 1445.9413629160053, 290, 4569, 2001.4000000000005, 2236.0, 3619.7599999999948, 0.6999429840421875, 237.4670045015846, 0.43701156167706784], "isController": false}, {"data": ["Home page-4", 631, 0, 0.0, 440.29952456418374, 158, 2772, 765.8000000000001, 973.5999999999997, 1339.3999999999996, 0.7010706048094999, 108.16322539558826, 0.1328200169267998], "isController": false}, {"data": ["Home page-3", 631, 0, 0.0, 226.07448494453237, 27, 1824, 430.60000000000014, 524.5999999999998, 971.4799999999907, 0.7009646873764147, 0.68372328023424, 0.43559585782358795], "isController": false}, {"data": ["Home page-6", 631, 1, 0.15847860538827258, 285.9096671949285, 1, 2946, 511.2000000000003, 593.0, 1068.639999999999, 0.7012131765845918, 5.923316598721591, 0.4008721512520156], "isController": false}, {"data": ["Home page", 631, 2, 0.31695721077654515, 4050.0269413629185, 1327, 10747, 5497.800000000001, 6098.2, 7350.199999999999, 0.6986897629216083, 1327.8148443927378, 5.408765388683551], "isController": false}, {"data": ["Home page-5", 631, 0, 0.0, 428.75752773375615, 140, 3957, 644.8000000000001, 804.3999999999999, 1510.759999999996, 0.7011227964910527, 25.06666343744618, 0.4014595989794274], "isController": false}, {"data": ["Open search", 630, 1, 0.15873015873015872, 4460.50476190476, 1367, 9317, 5773.7, 6387.499999999998, 7857.289999999997, 0.6995118961435798, 1312.982976791611, 5.740252391942067], "isController": false}, {"data": ["Home page-8", 631, 0, 0.0, 420.91759112519793, 128, 3294, 636.8000000000001, 763.1999999999999, 1435.2799999999988, 0.7013254049848564, 22.630972093903694, 0.40157561164522493], "isController": false}, {"data": ["Home page-7", 631, 0, 0.0, 351.38034865293173, 156, 3052, 543.4000000000002, 659.3999999999995, 1350.1199999999983, 0.7012357752489331, 12.981995410295163, 0.4015242900821257], "isController": false}, {"data": ["Home page-9", 631, 0, 0.0, 254.07448494453237, 45, 2972, 410.80000000000007, 538.5999999999997, 1196.0799999999986, 0.701399464224181, 6.461384645632093, 0.4016180176155753], "isController": false}, {"data": ["Open search-4", 630, 0, 0.0, 412.4730158730166, 101, 5513, 655.9, 793.8999999999999, 1329.389999999998, 0.701842727071188, 22.648941966866897, 0.40320708008916745], "isController": false}, {"data": ["Open search-3", 630, 0, 0.0, 204.48253968253985, 29, 1725, 337.5999999999999, 464.1499999999995, 636.0699999999998, 0.7021947486978746, 0.6849315903485004, 0.4376961686916997], "isController": false}, {"data": ["Open search-6", 630, 0, 0.0, 292.9396825396822, 50, 3394, 489.9, 674.799999999997, 1372.4499999999998, 0.7021430967631204, 7.743633118947498, 0.4033796418067145], "isController": false}, {"data": ["Open search-5", 630, 0, 0.0, 273.81428571428563, 50, 1720, 477.9, 585.4499999999999, 1184.6399999999908, 0.7021415316715983, 6.469600989615549, 0.40337874266512863], "isController": false}, {"data": ["Open search-0", 630, 0, 0.0, 743.4587301587301, 337, 2707, 968.6999999999999, 1095.3999999999992, 1573.2799999999993, 0.7020280811232449, 43.730697274765994, 0.4122586778471139], "isController": false}, {"data": ["Open search-2", 630, 0, 0.0, 3678.55396825397, 424, 8653, 5040.2, 5560.649999999996, 7115.939999999999, 0.6997799580798482, 839.7733511295893, 0.4375577249042801], "isController": false}, {"data": ["Open search-1", 630, 1, 0.15873015873015872, 1484.0507936507927, 0, 4193, 2229.8999999999996, 2572.7999999999997, 3229.039999999999, 0.701147544815014, 237.5004506072856, 0.43839980601584594], "isController": false}, {"data": ["facet English language-13", 622, 0, 0.0, 116.26688102893901, 45, 2464, 160.10000000000014, 237.0, 1071.6799999999967, 0.701882670494297, 4.782991738561682, 0.40371962199330164], "isController": false}, {"data": ["facet English language-11", 622, 0, 0.0, 150.05787781350506, 44, 2431, 227.70000000000005, 312.75000000000034, 1135.4199999999955, 0.7015842042038655, 8.847265323185553, 0.4035479455821062], "isController": false}, {"data": ["facet English language-12", 622, 0, 0.0, 126.33601286173631, 45, 2624, 206.4000000000001, 289.10000000000014, 1067.6099999999983, 0.7016008229709975, 7.865671271674051, 0.4035575046190601], "isController": false}, {"data": ["Open search-8", 630, 0, 0.0, 299.29682539682517, 66, 1678, 530.8, 645.0499999999994, 1284.4499999999998, 0.7021204036189291, 8.951530148827235, 0.40336660464603097], "isController": false}, {"data": ["Open search-7", 630, 0, 0.0, 282.23968253968275, 116, 1490, 481.4999999999999, 622.8999999999999, 1284.69, 0.7021783131670695, 7.96415754136722, 0.4033998735521752], "isController": false}, {"data": ["facet English language", 623, 1, 0.16051364365971107, 4442.412520064202, 1, 8761, 5725.400000000001, 6154.799999999999, 8030.5999999999985, 0.6966420288720662, 1215.0999096961696, 5.73603387533686], "isController": false}, {"data": ["facet English language-10", 622, 0, 0.0, 242.64147909967852, 42, 2877, 455.60000000000036, 565.0, 1226.6799999999985, 0.7015818301585439, 7.513743261585688, 0.4035465800423656], "isController": false}, {"data": ["Open search-9", 630, 0, 0.0, 497.66507936507924, 151, 2184, 774.3999999999996, 937.5499999999987, 1468.459999999998, 0.7021970966936548, 34.92825581555734, 0.403410664646271], "isController": false}, {"data": ["Home page-10", 631, 1, 0.15847860538827258, 226.03961965134715, 44, 2518, 386.40000000000055, 548.3999999999997, 1036.4399999999996, 0.7015382699688254, 7.725491726490129, 0.4010580018444564], "isController": false}, {"data": ["Home page-11", 631, 0, 0.0, 140.97464342313782, 43, 2354, 241.0, 366.5999999999999, 775.0799999999947, 0.7015491896050645, 7.955144412052304, 0.4017037496608994], "isController": false}, {"data": ["load item page", 619, 0, 0.0, 4126.159935379647, 2072, 8996, 5516.0, 5982.0, 7258.399999999996, 0.6973225742130338, 1113.5526383140452, 2.5100888755363693], "isController": false}, {"data": ["Home page-12", 631, 0, 0.0, 264.11568938193307, 93, 1730, 389.80000000000007, 482.9999999999998, 1057.7599999999998, 0.7012326581051826, 29.091160089276585, 0.40152250522034927], "isController": false}, {"data": ["Home page-13", 631, 0, 0.0, 184.5039619651346, 77, 1263, 257.80000000000007, 376.79999999999984, 906.8399999999981, 0.7015476296362181, 14.804697923152183, 0.40170285643011205], "isController": false}, {"data": ["facet English language-8", 622, 0, 0.0, 357.26848874598085, 101, 3063, 550.8000000000002, 770.7500000000003, 1405.0299999999993, 0.7012962706146715, 14.801863676165173, 0.40338232753129055], "isController": false}, {"data": ["facet English language-9", 622, 0, 0.0, 427.8778135048234, 136, 3189, 684.1000000000001, 802.5000000000002, 1409.62, 0.7010923289002206, 24.701143279968033, 0.40326502121311514], "isController": false}, {"data": ["facet English language-4", 622, 0, 0.0, 285.096463022508, 45, 2243, 509.8000000000002, 658.5000000000002, 1529.1599999999999, 0.7007566369089197, 6.4572925022419705, 0.4030719327532751], "isController": false}, {"data": ["facet English language-5", 622, 0, 0.0, 271.8392282958198, 51, 2507, 456.2000000000003, 562.3500000000003, 1225.0299999999993, 0.7007858490831761, 7.729110260048446, 0.4030887354589753], "isController": false}, {"data": ["Open search-11", 630, 0, 0.0, 321.6158730158727, 114, 1911, 476.69999999999993, 621.5999999999995, 1495.6899999999941, 0.7021783131670695, 29.131861137202858, 0.4033998735521752], "isController": false}, {"data": ["facet English language-6", 622, 0, 0.0, 279.9871382636653, 51, 3213, 482.80000000000064, 600.7, 1269.3299999999977, 0.7007605843577168, 7.948549838568758, 0.4030742033073196], "isController": false}, {"data": ["Open search-10", 630, 0, 0.0, 428.20793650793655, 135, 2751, 661.0, 836.7999999999997, 1935.3899999999744, 0.7022205775151201, 31.488080336890324, 0.4034241543257902], "isController": false}, {"data": ["facet English language-7", 622, 0, 0.0, 302.3504823151125, 122, 2215, 499.70000000000005, 607.0, 1354.5899999999988, 0.7008458601080113, 8.935784716377144, 0.4031232535191589], "isController": false}, {"data": ["facet English language-0", 622, 0, 0.0, 780.688102893891, 328, 4111, 1046.8000000000002, 1177.65, 2308.4499999999985, 0.698258171416768, 45.18355079294961, 0.43163810791681073], "isController": false}, {"data": ["facet English language-1", 622, 0, 0.0, 1403.0192926045013, 141, 4309, 2042.3000000000004, 2325.4000000000005, 3063.77, 0.6995098932291491, 237.3200784572883, 0.4385599135284314], "isController": false}, {"data": ["facet English language-2", 622, 0, 0.0, 3650.5353697749206, 759, 7758, 4896.4, 5290.3, 6928.699999999998, 0.6981390441556109, 837.8041347569, 0.437018679007565], "isController": false}, {"data": ["facet English language-3", 622, 0, 0.0, 230.55144694533755, 25, 2655, 418.4000000000001, 539.9500000000002, 921.889999999999, 0.700777164128321, 0.6835737255319484, 0.43730137488085663], "isController": false}, {"data": ["Open search-13", 630, 0, 0.0, 191.56825396825394, 77, 1488, 266.9, 431.7499999999976, 1180.6799999999957, 0.7021861395143546, 14.819514825601484, 0.40340436977122107], "isController": false}, {"data": ["Open search-12", 630, 0, 0.0, 302.6142857142861, 127, 3274, 462.69999999999993, 658.3499999999998, 1438.7699999999863, 0.7021626609958673, 28.906237156622957, 0.4033908814147575], "isController": false}]}, function(index, item){
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
    createTable($("#errorsTable"), {"supportsControllersDiscrimination": false, "titles": ["Type of error", "Number of errors", "% in errors", "% in all samples"], "items": [{"data": ["Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 5, 62.5, 0.014000112000896008], "isController": false}, {"data": ["Assertion failed", 3, 37.5, 0.008400067200537605], "isController": false}]}, function(index, item){
        switch(index){
            case 2:
            case 3:
                item = item.toFixed(2) + '%';
                break;
        }
        return item;
    }, [[1, 1]]);

        // Create top5 errors by sampler
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 35714, 8, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 5, "Assertion failed", 3, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["Home page-2", 631, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["Home page-6", 631, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}, {"data": ["Home page", 631, 2, "Assertion failed", 2, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": ["Open search", 630, 1, "Assertion failed", 1, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["Open search-1", 630, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["facet English language", 623, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": ["Home page-10", 631, 1, "Non HTTP response code: org.apache.http.NoHttpResponseException\/Non HTTP response message: tenejo.curationexperts.com:443 failed to respond", 1, null, null, null, null, null, null, null, null], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
