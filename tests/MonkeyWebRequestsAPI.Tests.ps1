﻿# PSScriptAnalyzer - ignore test file
Import-Module Pester
Set-StrictMode -Version Latest

Describe 'Star Wars' {
    BeforeAll {
        $Module = Get-ChildItem ("{0}/core/modules/monkeywebrequest" -f (Split-Path $PSScriptRoot -Parent)) -Filter '*.psm1'
        $MyModule = $Module.DirectoryName
        Import-Module $MyModule -Force
    }
    It 'Get Han Solo height' {
        Invoke-UrlRequest -url "https://swapi.dev/api/people/14" | Select-Object -ExpandProperty height | Should -Be '180'
    }

    It 'Han Solo is Id = 14' {
        $Han = Invoke-UrlRequest -url "https://swapi.dev/api/people/14"
        $Han.name | Should -Be 'Han Solo'
    }
}