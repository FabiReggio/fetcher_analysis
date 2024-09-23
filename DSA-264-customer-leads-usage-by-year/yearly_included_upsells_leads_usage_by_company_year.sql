select
    temp.company_id
    , comp.name as company_name
    , temp.year
    , count(distinct temp.contract_id) as contract_count
    , sum(temp.curr_year_overdue) as contract_months_overdue
    , sum(temp.curr_year_contract_months) as total_contract_months
    -- Fetcher leads
    , div0(sum(temp.included_fetcher_leads_usage), sum(temp.included_fetcher_leads_paid)) as included_fetcher_leads_usage
    , round(sum(temp.included_fetcher_leads_paid), 0) as included_fetcher_leads_paid
    , div0(sum(temp.upsell_fetcher_leads_usage), sum(temp.upsell_fetcher_leads_paid)) as upsell_fetcher_leads_usage
    , round(sum(temp.upsell_fetcher_leads_paid), 0) as upsell_fetcher_leads_paid
    -- Extension leads
    , div0(sum(temp.included_extension_leads_usage), sum(temp.included_extension_leads_paid)) as included_extension_leads_usage
    , round(sum(temp.included_extension_leads_paid), 0) as included_extension_leads_paid
    , div0(sum(temp.upsell_extension_leads_usage), sum(temp.upsell_extension_leads_paid)) as upsell_extension_leads_usage
    , round(sum(temp.upsell_extension_leads_paid), 0) as upsell_extension_leads_paid
from (
    select
        c.company_id
        , c.id as contract_id
        , c.start_date as contract_start_date
        , c.end_date as contract_end_date
        , cal.year
        , round(months_between(c.end_date, c.start_date), 0) as contract_months
        , round(
            months_between(
                least(
                    c.end_date
                    , current_date
                )
                , c.start_date)
        , 0) as total_overdue
        , year(c.start_date) as contract_start_year
        , year(c.end_date) as contract_end_year
        , (contract_start_year != contract_end_year) as cross_year_contract
        , iff(
            (cross_year_contract and (contract_start_year = cal.year))
            , round(months_between(date_from_parts(contract_start_year, 12, 31), c.start_date), 0)
            , null
        ) as initial_year_overdue
        , iff(
            (cross_year_contract and (contract_end_year = cal.year))
            , round(months_between(c.end_date, date_from_parts(contract_end_year, 1, 1)), 0)
            , null
        ) as ending_year_overdue
        , case
            when (contract_start_year = cal.year) then round(
                months_between(
                    least(
                        date_from_parts(contract_start_year, 12, 31)
                        , current_date
                    )
                    , c.start_date
                )
                , 0
                )
            when (contract_end_year = cal.year) and (contract_end_year > year(current_date)) then 0
            when (contract_end_year = cal.year) then round(
                months_between(
                    c.end_date
                    , least(
                        date_from_parts(contract_end_year, 1, 1)
                        , current_date
                    )
                )
                , 0
                )
            when ((contract_start_year != cal.year) and (contract_end_year != cal.year)) then round(
                months_between(
                    least(
                        date_from_parts(cal.year, 12, 31)
                        , current_date
                    )
                    , date_from_parts(cal.year, 1, 1)
                )
                , 0
                )
            else null -- CHECK FOR NULL CASES
        end as curr_year_overdue
        , case
            when (contract_start_year = cal.year) then round(
                months_between(
                    date_from_parts(contract_start_year, 12, 31)
                    , c.start_date
                )
                , 0
                )
            when (contract_end_year = cal.year) then round(
                months_between(
                    c.end_date
                    , date_from_parts(contract_end_year, 1, 1)
                )
                , 0
                )
            when ((cal.year > contract_start_year) and (cal.year < contract_end_year)) then 12
            else null -- CHECK FOR NULL CASES
        end as curr_year_contract_months
        , iff(
            zeroifnull(initial_year_overdue) + zeroifnull(ending_year_overdue) = 0
            , round(months_between(least(c.end_date, current_date), c.start_date), 0)
            , zeroifnull(initial_year_overdue) + zeroifnull(ending_year_overdue)
        ) as curr_year_overdue_iff
    -- INCLUDED VS UPSELLS
        -- Fetcher leads
        , ct.managed_leads_paid as tflp -- Total Fetcher leads paid
        , ct.managed_leads_used as tflu -- Total Fetcher leads used
        , ml_addon.leads_upsell as uflp -- Upsell Fetcher leads paid
        , (tflp - zeroifnull(uflp)) as  iflp -- Included Fetcher leads paid
        , case
            when tflu >= iflp then iflp
            else tflu
        end as iflu -- Included Fetcher leads used
        , case
            when tflu >= iflp then (tflu - iflp)
            else 0
        end as uflu -- Upsell Fetcher leads used
        -- Extension leads
        , ct.self_served_leads_paid as telp -- Total Extension leads paid
        , ct.self_served_leads_used as telu -- Total Extension leads used
        , ssl_addon.leads_upsell as uelp -- Upsell Extension leads paid
        , (telp - zeroifnull(uelp)) as  ielp -- Included Extension leads paid
        , case
            when telu >= ielp then ielp
            else telu
        end as ielu -- Included Extension leads used
        , case
            when telu >= ielp then (telu - ielp)
            when uelp is null then null
            else 0
        end as uelu -- Upsell Extension leads used
    -- USAGE METRICS COMPUTATION
        -- Fetcher leads
        -- Included leads
        , iflu * (curr_year_overdue / total_overdue) as included_fetcher_leads_usage
        , iflp * (curr_year_contract_months / contract_months) as included_fetcher_leads_paid
        -- Upsell leads
        , uflu * (curr_year_overdue / total_overdue) as upsell_fetcher_leads_usage
        , uflp * (curr_year_contract_months / contract_months) as upsell_fetcher_leads_paid
        -- Extension leads
        -- Included leads
        , ielu * (curr_year_overdue / total_overdue) as included_extension_leads_usage
        , ielp * (curr_year_contract_months / contract_months) as included_extension_leads_paid
        -- Upsell leads
        , uelu * (curr_year_overdue / total_overdue) as upsell_extension_leads_usage
        , uelp * (curr_year_contract_months / contract_months) as upsell_extension_leads_paid
    from base_db.aurora_caliber.contract_vw as c
    inner join (
        select distinct year
        from dimension_db.date.calendar
    ) as cal on cal.year between year(c.start_date) and year(c.end_date)
    left join base_db.aurora_caliber.contract_trackings_vw as ct on ct.contract_id = c.id
    -- FETCHER LEADS ADD ONS
    left join (
        select
            cmlao.contract_id
            , sum(lao.amount) as leads_upsell
        from base_db.aurora_caliber.contract_managed_lead_add_ons_vw as cmlao
        left join base_db.aurora_caliber.lead_add_ons_vw as lao on lao.id = cmlao.lead_add_on_id
        group by
            cmlao.contract_id
    ) as ml_addon on ml_addon.contract_id = c.id
    -- EXTENSION LEADS ADD ONS
    left join (
        select
            csslao.contract_id
            , sum(lao.amount) as leads_upsell
        from base_db.aurora_caliber.contract_self_served_lead_add_ons_vw as csslao
        left join base_db.aurora_caliber.lead_add_ons_vw as lao on lao.id = csslao.lead_add_on_id
        group by
            csslao.contract_id
    ) as ssl_addon on ssl_addon.contract_id = c.id
    where true
        and round(months_between(c.end_date, c.start_date), 0) > 0       
        and c.company_id in (
            2911729
            , 773841
            , 2215226
            , 1129603
            , 2648530
            , 1539873
            , 1990930
            , 1765939
            , 236949
            , 2122571
            , 1795298
            , 2009905
            , 1293150
            , 683882
            , 2139597
            , 74036
            , 2454601
            , 1068096
            , 738656
            , 326836
            , 3221382
            , 684566
            , 1237287
            , 877463
            , 1425828
            , 764677
            , 2496147
            , 496784
            , 372967
            , 1134456
            , 35350
            , 3350490
            , 756545
            , 206915
            , 1650563
            , 1959974
            , 75893
            , 2340492
            , 859249
            , 955
            , 562418
            , 123491
            , 1894400
            , 327599
            , 132638
            , 97103
            , 1503321
            , 2745046
            , 48845
            , 2924508
            , 2391813
            , 1640527
            , 2848726
            , 1662685
            , 2861898
            , 1816705
            , 2295800
            , 1007489
            , 1398802
            , 3365650
            , 2448547
            , 939215
            , 1899801
            , 349163
            , 1458035
            , 2158528
            , 3052326
            , 3090219
            , 1715123
            , 2804301
            , 583443
            , 102346
            , 397580
            , 2220480
            , 213013
            , 3408166
            , 61373
            , 2817703
            , 1196544
            , 697112
            , 289725
            , 3088389
            , 2187166
            , 1816531
            , 159981
            , 1944009
            , 1391871
            , 1429488
            , 2229119
            , 729650
            , 3277184
            , 1868481
            , 2388185
            , 1831709
            , 3212263
            , 282056
            , 1479695
            , 569017
            , 24663
            , 234257
            , 358979
            , 495419
            , 3232730
            , 2334250
            , 228314
            , 1625420
            , 28366
            , 337738
            , 2099129
            , 3265589
            , 1688517
            , 970295
            , 1890530
            , 3404265
            , 112893
            , 2269166
            , 3304081
            , 1294959
            , 293317
            , 292470
            , 2840030
            , 1694040
            , 2722148
            , 596395
            , 650689
            , 37173
            , 2263534
            , 327408
            , 2311680
            , 64107
            , 1854472
            , 1453319
            , 63594
            , 2967007
            , 1737301
            , 1593686
            , 1288739
            , 2863513
            , 385747
            , 454861
            , 2849311
            , 490079
            , 30123
            , 820291
            , 293143
            , 981118
            , 2677002
            , 3202599
            , 753304
            , 1999198
            , 593893
            , 3049932
            , 1237173
            , 2495591
            , 133332
            , 3251181
            , 2534971
            , 1043164
            , 3360623
            , 450439
            , 607713
            , 1163885
            , 1930663
            , 1833588
            , 3012649
            , 2826334
            , 2977413
            , 35420
            , 280254
            , 129881
            , 127318
            , 2865327
            , 3404321
            , 105721
            , 2384164
            , 457692
            , 2406981
            , 503151
            , 3286304
            , 244788
            , 462561
            , 2534377
            , 132981
            , 1042267
            , 1729850
            , 141027
            , 1087093
            , 1686042
            , 575839
            , 225444
            , 1891459
            , 2454955
            , 56117
            , 2838550
            , 3269672
            , 1838905
            , 727
            , 42092
            , 2329477
            , 1414935
            , 1645333
            , 2811062
            , 558016
            , 1719419
            , 2322217
            , 87711
            , 460025
            , 44810
            , 267966
            , 38402
            , 2419264
            , 971171
            , 2633913
            , 264373
            , 2570617
            , 324056
            , 2134284
            , 2155899
            , 1704323
            , 1941522
            , 2810933
            , 1817953
            , 155138
            , 346953
            , 2076388
            , 17861
            , 91339
            , 1762000
            , 2009306
            , 3053750
            , 3148698
            , 33617
            , 1934991
            , 3106953
            , 1567722
            , 3377585
            , 1834581
            , 519572
            , 1387001
            , 124421
            , 2150126
            , 139853
            , 2364153
            , 243357
            , 1762322
            , 24907
            , 174606
            , 268189
            , 466159
            , 3144005
            , 2908055
            , 372508
            , 189638
            , 1852090
            , 1759561
            , 235586
            , 6335
            , 2183013
            , 171560
            , 2060365
            , 2523393
            , 2389899
            , 270303
            , 175103
            , 312613
            , 1929661
            , 1945937
            , 2630148
            , 13578
            , 1903073
            , 2523613
            , 2478077
            , 2465364
            , 3301277
            , 1702070
            , 21313
            , 659056
            , 18615
            , 207664
            , 1940268
            , 1762936
            , 2770260
            , 464282
            , 47705
            , 151723
            , 3235162
            , 3238014
            , 2325239
            , 1421348
            , 1755097
            , 730524
            , 354734
            , 1363713
            , 2294152
            , 731463
            , 1722
            , 2307707
            , 458268
            , 2669322
            , 1895705
            , 1665415
            , 1449523
            , 1623609
            , 207623
            , 1923820
            , 250817
            , 703386
            , 1815015
            , 123768
            , 3038037
            , 303075
            , 843922
            , 17492
            , 318366
            , 563176
            , 1810544
            , 2322712
            , 2634902
            , 1918489
            , 1698785
            , 543920
            , 1709101
            , 1670323
            , 218632
            , 2467841
            , 1771362
            , 2785904
            , 2549297
            , 3144156
            , 2971684
            , 47509
            , 458678
            , 236494
            , 162569
            , 285818
            , 332678
            , 684051
            , 446296
            , 2695669
            , 2780978
            , 796441
            , 365286
            , 2212887
            , 145152
            , 2156254
            , 367154
            , 2664734
            , 1670529
            , 1953857
            , 1628898
            , 341537
            , 1775923
            , 1252376
            , 153181
            , 309
            , 990452
            , 2448691
            , 306054
            , 2761222
            , 2331756
            , 2786736
            , 2565735
            , 364173
            , 2598057
            , 272124
            , 2454578
            , 1797660
            , 2524652
            , 528779
            , 2419338
            , 2034604
            , 3017218
            , 2060142
            , 3150769
            , 22997
            , 1458619
            , 1122356
            , 333247
            , 34242
            , 1648361
            , 1124343
            , 3214984
            , 721697
            , 3339545
            , 1792435
            , 595973
            , 3434415
            , 2695804
            , 1589275
            , 1857032
            , 2003801
            , 583311
            , 192133
            , 319634
            , 33375
            , 458698
            , 894967
            , 2877975
            , 690280
            , 1940953
            , 2293809
            , 172904
            , 337349
            , 198526
            , 1973717
            , 2783328
            , 2479314
            , 143518
            , 2364532
            , 309229
            , 2085893
            , 1817885
            , 1995821
            , 2085881
            , 29272
            , 2215289
            , 1596303
            , 798901
            , 2450671
            , 776224
            , 2726637
            , 90761
            , 1946060
            , 1258091
            , 581008
            , 1525870
            , 1764017
            , 1704684
            , 1789214
            , 796613
            , 1169315
            , 337230
            , 2891783
            , 2794801
            , 1873474
            , 1811571
            , 2324196
            , 1498137
            , 1478559
            , 316956
            , 221104
            , 280352
            , 745732
            , 2009301
            , 1082192
            , 2459927
            , 571457
            , 271643
            , 644518
            , 3077968
            , 2055087
            , 115634
            , 6059
            , 2836398
            , 2528959
            , 1010779
            , 544826
            , 1829717
            , 725698
            , 8876
            , 2146855
            , 1172424
            , 405081
            , 1700011
            , 7103
            , 3049221
            , 2754063
            , 1450647
            , 2404293
            , 645951
            , 84328
            , 576497
            , 2046415
            , 412303
            , 2476363
            , 138339
            , 235
            , 3240244
            , 9825
            , 2988035
            , 1830857
            , 246780
            , 299985
            , 318389
            , 3399565
            , 186582
            , 315365
            , 7633
            , 2909256
            , 1769752
            , 12587
            , 796521
            , 67463
            , 3347
            , 2089707
            , 1704
            , 2474427
            , 252267
            , 2652307
            , 895927
            , 256663
            , 458531
            , 1750773
            , 2106764
            , 31444
            , 345368
            , 3458934
            , 423419
            , 2806955
            , 2782882
            , 1692223
            , 3113523
            , 2789988
            , 3510326
            , 485935
            , 1926345
            , 1797844
            , 1750574
            , 2422383
            , 2694231
            , 1660836
            , 1194830
            , 268771
            , 91638
            , 3326855
            , 419666
            , 2766113
            , 430343
            , 1830195
            , 1899849
            , 1778861
            , 2092230
            , 2334512
            , 128677
            , 30910
            , 2322871
            , 309436
            , 2951982
            , 27187
            , 1886167
            , 58702
            , 691594
            , 2870211
            , 9534
            , 393937
            , 2754683
            , 922700
            , 456181
            , 825893
            , 636525
            , 1815546
            , 435507
            , 1836695
            , 992034
            , 1853679
            , 1793141
            , 332438
            , 1456277
            , 583549
            , 2217396
            , 1765591
            , 1509523
            , 1722811
            , 236953
            , 1807252
            , 1173665
            , 18778
            , 2108010
            , 140342
            , 1822011
            , 2115450
            , 39921
            , 2797582
            , 1220347
            , 1173850
            , 1068162
            , 1874348
            , 1372340
            , 384325
            , 2869555
            , 763521
            , 403521
            , 1820757
            , 2684946
            , 493323
            , 3094319
            , 1071570
            , 3109364
            , 2414893
            , 2861923
            , 1969469
            , 2477855
            , 3253011
            , 280005
            , 3089187
            , 3301586
            , 558653
            , 1895353
            , 3296690
            , 74441
            , 243767
        )
        and c.status in (
            0 -- EXPIRED
            , 1 -- ACTIVE
        )
    qualify row_number() over (partition by c.id, cal.year order by c.start_date) = 1
) as temp
left join base_db.aurora_caliber.companies_vw as comp on temp.company_id = comp.id
where true
    -- and temp.year <= year(current_date)
group by
    temp.company_id
    , comp.name
    , temp.year
order by
    temp.company_id
    , temp.year
;