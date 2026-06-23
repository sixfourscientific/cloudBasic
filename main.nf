#!/usr/bin/env nextflow

/* enable dsl syntax extension (should be applied by default) */
nextflow.enable.dsl = 2




// IMPORTS

import java.nio.file.Files

// FUNCTIONS

params.PUBLISH = true

params.importMap = [ 'subworkflows', 'functions' ]

        .collectEntries { subDir -> 

                def subPath = [ workflow.projectDir, 'pipeline', 'components', subDir, ]
                
                        .join('/')
                
                return [ (subDir) : subPath ] }

include { 
    parseSupplementary as parseSupplementary;
    viewMeta as viewMeta;
    prepBridge as prepBridge;
    } from "$params.importMap.functions/core/Utils"

// SUBWORKFLOWS

include { 
    Info_Parse as ParseInfo;
    } from "${params.importMap.subworkflows}/core/Info_Parse"

include {
    SUBWORKFLOW as Branch1;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Branch1"

include {
    SUBWORKFLOW as Branch2;
    } from "${params.importMap.subworkflows}/branches/BRANCH_Branch2"

////BRANCH_IMPORT////


// SETUP

parseSupplementary( params.supplementary, params )

Parameters = params

EXECUTE  = params.execute.split(',')

RUN_ALL  = EXECUTE.contains('all')

RUN_BRANCH1 = RUN_ALL ?: EXECUTE.contains('branch1')

RUN_BRANCH2 = RUN_ALL ?: EXECUTE.contains('branch2')

////BRANCH_FILTER////


workflow { 

    main:

        println('PARSING INPUTS...')

        // MAIN

        def InputMeta = params.INPUT.MAIN + [
            INFO     : params.inputs,
            TYPE     : "SAMPLES",
            DETAILED : true,
            ]

     // Inputs = ParseInfo( InputMeta )
        Inputs = Channel.of(
            [input : 1],
            [input : 2],
            [input : 3],
            )

        // SUPPLEMENTARY

        def SUPPLEMENTARYMeta = [
            INFO : params.SUPPLEMENTARY,
            TYPE : "SUPPLEMENTARY",
            ]

        SUPPLEMENTARY = ParseInfo( SUPPLEMENTARYMeta )


        // BRANCHES

        println('RUNNING BRANCHES...')
        
        // BRANCH( Inputs|BRANCH.out.Main)

        Branch1( Parameters, Inputs | filter { RUN_BRANCH1 }  )

        Branch2( Parameters, Inputs | filter { RUN_BRANCH2 }  )

        ////BRANCH_RUN////


    /*
    */


    publish: 
    
        Branch1 = Branch1.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )      
            
            return indexMetaNew }

        Branch2 = Branch2.out.Main.map{ coreMeta -> 
        
            def indexMeta = [:]
            
            def indexMetaNew = prepBridge( 
                coreMeta  : coreMeta, 
                indexMeta : indexMeta, 
                BASIC     : false, 
                UPDATE    : false, 
                INTERIM   : false,
                )      
            
            return indexMetaNew }

        ////BRANCH_PUBLISH////

    }


output {

        Branch1 { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "branch1/$indexMeta.ID/$indexMeta.TAG" }
            index {
                path   'bridge-branch1.csv'
                header true
                sep    '\t'
                }
            }

        Branch2 { 
            enabled      false
            mode         'copy'
            overwrite    'standard'
            ignoreErrors false
            path { indexMeta -> 
                return "branch2/$indexMeta.ID/$indexMeta.TAG" }
            index {
                path   'bridge-branch2.csv'
                header true
                sep    '\t'
                }
            }

        ////BRANCH_OUTPUT////

    }
