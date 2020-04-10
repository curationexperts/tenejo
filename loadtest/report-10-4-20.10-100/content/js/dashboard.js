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
    createTable($("#apdexTable"), {"supportsControllersDiscrimination": true, "overall": {"data": [0.7499469394685457, 500, 1500, "Total"], "isController": false}, "titles": ["Apdex", "T (Toleration threshold)", "F (Frustration threshold)", "Label"], "items": [{"data": [0.01696969696969697, 500, 1500, "Subject search - African"], "isController": false}, {"data": [0.979951397326853, 500, 1500, "load item page-5"], "isController": false}, {"data": [0.9690157958687727, 500, 1500, "load item page-4"], "isController": false}, {"data": [0.9805589307411907, 500, 1500, "load item page-3"], "isController": false}, {"data": [0.9878787878787879, 500, 1500, "Subject search - African-3"], "isController": false}, {"data": [0.03523693803159174, 500, 1500, "load item page-2"], "isController": false}, {"data": [0.048484848484848485, 500, 1500, "Subject search - African-2"], "isController": false}, {"data": [0.479951397326853, 500, 1500, "load item page-1"], "isController": false}, {"data": [0.48787878787878786, 500, 1500, "Subject search - African-1"], "isController": false}, {"data": [0.9629404617253949, 500, 1500, "load item page-0"], "isController": false}, {"data": [0.9775757575757575, 500, 1500, "Subject search - African-0"], "isController": false}, {"data": [0.9668674698795181, 500, 1500, "Home page-0"], "isController": false}, {"data": [0.03433734939759036, 500, 1500, "Home page-2"], "isController": false}, {"data": [0.4746987951807229, 500, 1500, "Home page-1"], "isController": false}, {"data": [0.941566265060241, 500, 1500, "Home page-4"], "isController": false}, {"data": [0.9789156626506024, 500, 1500, "Home page-3"], "isController": false}, {"data": [0.9716867469879518, 500, 1500, "Home page-6"], "isController": false}, {"data": [0.01144578313253012, 500, 1500, "Home page"], "isController": false}, {"data": [0.9433734939759036, 500, 1500, "Home page-5"], "isController": false}, {"data": [6.045949214026602E-4, 500, 1500, "Open search"], "isController": false}, {"data": [0.9512048192771084, 500, 1500, "Home page-8"], "isController": false}, {"data": [0.9542168674698795, 500, 1500, "Home page-7"], "isController": false}, {"data": [0.9722891566265061, 500, 1500, "Home page-9"], "isController": false}, {"data": [0.9480048367593712, 500, 1500, "Open search-4"], "isController": false}, {"data": [0.9770253929866989, 500, 1500, "Open search-3"], "isController": false}, {"data": [0.9637243047158404, 500, 1500, "Open search-6"], "isController": false}, {"data": [0.9709794437726723, 500, 1500, "Open search-5"], "isController": false}, {"data": [0.658403869407497, 500, 1500, "Open search-0"], "isController": false}, {"data": [0.02418379685610641, 500, 1500, "Open search-2"], "isController": false}, {"data": [0.46432889963724305, 500, 1500, "Open search-1"], "isController": false}, {"data": [0.9963636363636363, 500, 1500, "facet English language-13"], "isController": false}, {"data": [0.9951515151515151, 500, 1500, "facet English language-11"], "isController": false}, {"data": [0.9987878787878788, 500, 1500, "facet English language-12"], "isController": false}, {"data": [0.9613059250302297, 500, 1500, "Open search-8"], "isController": false}, {"data": [0.9727932285368803, 500, 1500, "Open search-7"], "isController": false}, {"data": [0.0018181818181818182, 500, 1500, "facet English language"], "isController": false}, {"data": [0.9769696969696969, 500, 1500, "facet English language-10"], "isController": false}, {"data": [0.9310761789600968, 500, 1500, "Open search-9"], "isController": false}, {"data": [0.9849397590361446, 500, 1500, "Home page-10"], "isController": false}, {"data": [0.9951807228915662, 500, 1500, "Home page-11"], "isController": false}, {"data": [0.0054678007290400975, 500, 1500, "load item page"], "isController": false}, {"data": [0.9885542168674699, 500, 1500, "Home page-12"], "isController": false}, {"data": [0.9903614457831326, 500, 1500, "Home page-13"], "isController": false}, {"data": [0.9575757575757575, 500, 1500, "facet English language-8"], "isController": false}, {"data": [0.9454545454545454, 500, 1500, "facet English language-9"], "isController": false}, {"data": [0.9696969696969697, 500, 1500, "facet English language-4"], "isController": false}, {"data": [0.9648484848484848, 500, 1500, "facet English language-5"], "isController": false}, {"data": [0.973397823458283, 500, 1500, "Open search-11"], "isController": false}, {"data": [0.9624242424242424, 500, 1500, "facet English language-6"], "isController": false}, {"data": [0.9534461910519951, 500, 1500, "Open search-10"], "isController": false}, {"data": [0.9672727272727273, 500, 1500, "facet English language-7"], "isController": false}, {"data": [0.6612121212121213, 500, 1500, "facet English language-0"], "isController": false}, {"data": [0.4684848484848485, 500, 1500, "facet English language-1"], "isController": false}, {"data": [0.02484848484848485, 500, 1500, "facet English language-2"], "isController": false}, {"data": [0.9818181818181818, 500, 1500, "facet English language-3"], "isController": false}, {"data": [0.9945586457073761, 500, 1500, "Open search-13"], "isController": false}, {"data": [0.9800483675937122, 500, 1500, "Open search-12"], "isController": false}]}, function(index, item){
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
    createTable($("#statisticsTable"), {"supportsControllersDiscrimination": true, "overall": {"data": ["Total", 47116, 0, 0.0, 738.3072417013361, 23, 9271, 2493.9000000000015, 3076.0, 4149.980000000003, 37.90702015228459, 11532.900948590677, 40.274780527215405], "isController": false}, "titles": ["Label", "#Samples", "KO", "Error %", "Average", "Min", "Max", "90th pct", "95th pct", "99th pct", "Transactions\/s", "Received", "Sent"], "items": [{"data": ["Subject search - African", 825, 0, 0.0, 2646.025454545453, 846, 8008, 3688.6, 4157.799999999999, 5844.100000000001, 0.6724889263490127, 1043.4568784116077, 1.6520874973304227], "isController": false}, {"data": ["load item page-5", 823, 0, 0.0, 200.277035236938, 44, 1286, 337.0000000000002, 472.9999999999998, 722.28, 0.6731627278876677, 6.202977528388573, 0.3872000456306995], "isController": false}, {"data": ["load item page-4", 823, 0, 0.0, 235.68651275820153, 42, 1921, 385.20000000000005, 534.0, 801.52, 0.6731462101377619, 14.262119986522762, 0.3924494994650819], "isController": false}, {"data": ["load item page-3", 823, 0, 0.0, 163.16889428918594, 28, 1040, 263.6, 449.79999999999995, 654.52, 0.673228806994381, 0.6565992361654752, 0.42011055436465766], "isController": false}, {"data": ["Subject search - African-3", 825, 0, 0.0, 149.50060606060592, 23, 3311, 248.9999999999999, 420.7999999999997, 670.4200000000008, 0.6738577498542017, 0.6571612649821039, 0.42050302945003404], "isController": false}, {"data": ["load item page-2", 823, 0, 0.0, 2458.3669501822615, 732, 8124, 3391.2, 3754.5999999999995, 5767.079999999999, 0.671943697159956, 806.3683263930278, 0.4206210057417303], "isController": false}, {"data": ["Subject search - African-2", 825, 0, 0.0, 2409.972121212123, 561, 7422, 3425.8, 3810.7999999999993, 5530.500000000001, 0.6726907139327701, 807.2647287797677, 0.4210886207333063], "isController": false}, {"data": ["load item page-1", 823, 0, 0.0, 957.031591737547, 232, 4110, 1414.2, 1658.1999999999998, 2332.959999999999, 0.6727648756243307, 228.24641271682975, 0.42179204116291047], "isController": false}, {"data": ["Subject search - African-1", 825, 0, 0.0, 942.9696969696965, 210, 5086, 1368.0, 1696.7999999999997, 2648.6600000000008, 0.6735496638783071, 228.51258174826347, 0.42228406661120427], "isController": false}, {"data": ["load item page-0", 823, 0, 0.0, 338.0230862697443, 134, 2362, 458.6, 573.3999999999999, 842.3599999999999, 0.6731340976363424, 17.636083485446235, 0.3799526449548886], "isController": false}, {"data": ["Subject search - African-0", 825, 0, 0.0, 230.78666666666663, 64, 5102, 327.0, 474.39999999999986, 670.6600000000001, 0.6737152250657995, 7.639675457085156, 0.39056821907667527], "isController": false}, {"data": ["Home page-0", 830, 0, 0.0, 292.884337349398, 89, 1413, 421.79999999999995, 581.4499999999999, 957.729999999999, 0.6694001851738344, 12.466560077204827, 0.35947023074546985], "isController": false}, {"data": ["Home page-2", 830, 0, 0.0, 2528.412048192771, 560, 8740, 3505.9, 4085.599999999998, 5390.3599999999915, 0.6682247843767435, 801.905416807222, 0.4174124862027684], "isController": false}, {"data": ["Home page-1", 830, 0, 0.0, 981.1530120481922, 186, 5245, 1456.6, 1718.6999999999996, 2742.959999999989, 0.66921559868995, 227.04220739757372, 0.4186849379322689], "isController": false}, {"data": ["Home page-4", 830, 0, 0.0, 339.9963855421689, 118, 2773, 549.2999999999998, 742.0, 1342.419999999999, 0.6695033172679425, 103.29096974001291, 0.12683949565427818], "isController": false}, {"data": ["Home page-3", 830, 0, 0.0, 169.6253012048193, 24, 1291, 295.69999999999993, 473.6999999999996, 740.3799999999999, 0.6697426413035935, 0.6531881968752875, 0.41705253777994034], "isController": false}, {"data": ["Home page-6", 830, 0, 0.0, 221.91927710843365, 45, 1403, 374.79999999999995, 530.8999999999999, 1059.6999999999982, 0.6695211391216528, 5.6631805395009405, 0.38422314524494794], "isController": false}, {"data": ["Home page", 830, 0, 0.0, 2825.922891566268, 1034, 9041, 3783.8, 4416.45, 6123.419999999999, 0.6678613069321591, 1270.517771642277, 5.18551180505209], "isController": false}, {"data": ["Home page-5", 830, 0, 0.0, 329.99638554216955, 64, 1703, 532.5999999999999, 683.8999999999999, 1232.3299999999967, 0.6695983781197838, 23.94041098819006, 0.3842674709712968], "isController": false}, {"data": ["Open search", 827, 0, 0.0, 3157.7073760580383, 1327, 9271, 4217.0, 4883.799999999999, 6670.840000000009, 0.6683660027187222, 1254.8822931803231, 5.489171101898742], "isController": false}, {"data": ["Home page-8", 830, 0, 0.0, 324.4807228915665, 94, 1660, 495.0, 622.1499999999995, 1167.8999999999994, 0.6697221056708517, 21.612039200428462, 0.38433847543410904], "isController": false}, {"data": ["Home page-7", 830, 0, 0.0, 295.12650602409633, 151, 1289, 478.9, 578.5999999999995, 1140.7699999999982, 0.669635113406337, 12.397830220874704, 0.3842885525272271], "isController": false}, {"data": ["Home page-9", 830, 0, 0.0, 217.63614457831312, 48, 1424, 382.9, 520.7999999999997, 886.1099999999989, 0.6697918238592759, 6.171083688622254, 0.38437848513667383], "isController": false}, {"data": ["Open search-4", 827, 0, 0.0, 309.80773881499385, 62, 1743, 509.20000000000005, 661.3999999999987, 986.6000000000015, 0.670210326101491, 21.628348088563392, 0.38526441271300654], "isController": false}, {"data": ["Open search-3", 827, 0, 0.0, 180.36154776299884, 27, 1521, 284.60000000000014, 478.59999999999945, 666.7200000000007, 0.6704314595300981, 0.6539289186090533, 0.41812744039685973], "isController": false}, {"data": ["Open search-6", 827, 0, 0.0, 233.81499395405083, 50, 1224, 425.0, 551.3999999999992, 803.2000000000003, 0.6704195026411448, 7.394000017783951, 0.3853846559762994], "isController": false}, {"data": ["Open search-5", 827, 0, 0.0, 233.45223700120914, 42, 3411, 432.20000000000005, 527.9999999999995, 836.4000000000005, 0.6704216765892317, 6.177541246234452, 0.38538590565091707], "isController": false}, {"data": ["Open search-0", 827, 0, 0.0, 569.6916565900848, 271, 2416, 749.0000000000002, 882.1999999999989, 1278.080000000001, 0.6700447074570224, 41.73857080557684, 0.39433551435451275], "isController": false}, {"data": ["Open search-2", 827, 0, 0.0, 2580.6263603385737, 634, 8676, 3642.8000000000006, 4214.999999999998, 6145.800000000012, 0.6688292415055856, 802.6308631928287, 0.4184344935033793], "isController": false}, {"data": ["Open search-1", 827, 0, 0.0, 1028.0810157194664, 231, 3461, 1448.6000000000004, 1740.199999999999, 2740.32, 0.6701886009590099, 227.3724072483693, 0.41993942015719854], "isController": false}, {"data": ["facet English language-13", 825, 0, 0.0, 92.32121212121216, 40, 2329, 136.39999999999998, 195.69999999999993, 439.9000000000003, 0.6744554691798376, 4.596097871459415, 0.3879436243622308], "isController": false}, {"data": ["facet English language-11", 825, 0, 0.0, 95.73454545454544, 42, 669, 151.79999999999995, 222.39999999999986, 526.2600000000004, 0.6744532636589049, 8.505148652309533, 0.3879423557569287], "isController": false}, {"data": ["facet English language-12", 825, 0, 0.0, 89.28484848484847, 44, 699, 143.79999999999995, 189.0, 404.80000000000064, 0.674409156269185, 7.560806798739142, 0.3879169853931152], "isController": false}, {"data": ["Open search-8", 827, 0, 0.0, 251.53204353083444, 51, 1617, 452.60000000000014, 541.3999999999996, 958.0400000000043, 0.6704472215353808, 8.547946356368639, 0.3854005899347793], "isController": false}, {"data": ["Open search-7", 827, 0, 0.0, 224.02539298669888, 58, 3419, 330.60000000000014, 506.5999999999999, 1079.0000000000007, 0.6704146113094973, 7.604114839408544, 0.3853818442380418], "isController": false}, {"data": ["facet English language", 825, 0, 0.0, 3081.9721212121244, 1183, 9192, 4090.2, 4616.2, 6109.940000000003, 0.6730501736469449, 1175.8355624721094, 5.5506921059066885], "isController": false}, {"data": ["facet English language-10", 825, 0, 0.0, 191.48242424242392, 42, 1278, 301.0, 494.7999999999997, 886.7200000000007, 0.6744372740635132, 7.22300206515759, 0.38793315861661065], "isController": false}, {"data": ["Open search-9", 827, 0, 0.0, 360.08222490931036, 100, 2610, 560.4000000000001, 712.1999999999998, 1279.200000000001, 0.6704803785173872, 33.3508503426179, 0.3854196499293847], "isController": false}, {"data": ["Home page-10", 830, 0, 0.0, 177.34939759036143, 43, 1410, 264.0, 444.89999999999986, 936.8899999999952, 0.6698729097745756, 7.38713007176518, 0.3844250185223895], "isController": false}, {"data": ["Home page-11", 830, 0, 0.0, 105.8373493975903, 40, 917, 186.89999999999998, 245.0, 526.1999999999953, 0.6699772692049388, 7.597974369383896, 0.38448490805570984], "isController": false}, {"data": ["load item page", 823, 0, 0.0, 2799.7083839611155, 965, 8885, 3743.6000000000004, 4176.799999999999, 6100.16, 0.6718317987867845, 1072.8460783247306, 2.418332041336023], "isController": false}, {"data": ["Home page-12", 830, 0, 0.0, 204.0698795180723, 89, 1558, 281.0, 340.1499999999995, 762.2499999999985, 0.6699967388110545, 27.796173590857613, 0.38449608122539985], "isController": false}, {"data": ["Home page-13", 830, 0, 0.0, 148.84819277108443, 74, 778, 215.79999999999995, 288.44999999999993, 561.7599999999998, 0.6701184494912348, 14.142317200467145, 0.3845659282513057], "isController": false}, {"data": ["facet English language-8", 825, 0, 0.0, 288.24121212121224, 85, 1369, 474.0, 591.6999999999999, 903.1400000000001, 0.6744157720098652, 14.234513223300697, 0.3879207907361432], "isController": false}, {"data": ["facet English language-9", 825, 0, 0.0, 336.5127272727269, 74, 1643, 530.0, 670.0, 1149.8200000000004, 0.674361747259026, 23.75935047903185, 0.3878897159527015], "isController": false}, {"data": ["facet English language-4", 825, 0, 0.0, 218.58787878787874, 45, 1764, 403.19999999999993, 521.4999999999997, 900.22, 0.6744560205623247, 6.214919025934265, 0.38794394151485273], "isController": false}, {"data": ["facet English language-5", 825, 0, 0.0, 234.40484848484834, 45, 1676, 459.0, 533.6999999999999, 1086.7, 0.6744532636589049, 7.438699766772018, 0.3879423557569287], "isController": false}, {"data": ["Open search-11", 827, 0, 0.0, 237.4800483675938, 80, 1716, 356.60000000000014, 503.7999999999997, 955.6800000000026, 0.6705265863386086, 27.81890058470405, 0.38544621208220803], "isController": false}, {"data": ["facet English language-6", 825, 0, 0.0, 241.04242424242432, 49, 1212, 464.4, 540.6999999999999, 972.6600000000001, 0.6744416849106549, 7.650012883369004, 0.3879356957152107], "isController": false}, {"data": ["Open search-10", 827, 0, 0.0, 301.7581620314391, 103, 1892, 479.60000000000036, 608.3999999999996, 1058.88, 0.6705352849937122, 30.067509004236857, 0.385451212426308], "isController": false}, {"data": ["facet English language-7", 825, 0, 0.0, 246.52242424242448, 118, 1477, 428.79999999999995, 540.0, 907.9800000000002, 0.6743777332733886, 8.598316099235706, 0.38789891103322843], "isController": false}, {"data": ["facet English language-0", 825, 0, 0.0, 565.4836363636359, 230, 2435, 720.0, 824.0, 1334.8600000000008, 0.6742234172094506, 43.62815774069776, 0.41678068661482637], "isController": false}, {"data": ["facet English language-1", 825, 0, 0.0, 1001.0666666666666, 259, 4553, 1402.0, 1696.5999999999995, 2670.5600000000013, 0.6741468365353265, 228.71530828249652, 0.42265846587468714], "isController": false}, {"data": ["facet English language-2", 825, 0, 0.0, 2511.2278787878813, 812, 7306, 3545.8, 3909.7, 5084.460000000003, 0.6733803366411952, 808.0924395419238, 0.42152030838574817], "isController": false}, {"data": ["facet English language-3", 825, 0, 0.0, 188.06545454545451, 25, 1376, 323.7999999999995, 468.0, 725.3400000000004, 0.6744532636589049, 0.6578849296381742, 0.42087464402152364], "isController": false}, {"data": ["Open search-13", 827, 0, 0.0, 144.77267230955266, 45, 780, 213.0, 282.0, 510.36000000000035, 0.6706543705255918, 14.15429508837919, 0.3855196676794061], "isController": false}, {"data": ["Open search-12", 827, 0, 0.0, 212.53083434099145, 71, 1376, 311.4000000000001, 438.1999999999998, 768.6000000000008, 0.6705042970650236, 27.60314792950381, 0.3854333992926058], "isController": false}]}, function(index, item){
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
    createTable($("#top5ErrorsBySamplerTable"), {"supportsControllersDiscrimination": false, "overall": {"data": ["Total", 47116, 0, null, null, null, null, null, null, null, null, null, null], "isController": false}, "titles": ["Sample", "#Samples", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors", "Error", "#Errors"], "items": [{"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}, {"data": [], "isController": false}]}, function(index, item){
        return item;
    }, [[0, 0]], 0);

});
