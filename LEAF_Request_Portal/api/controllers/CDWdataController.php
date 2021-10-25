<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

require '../sources/CDW.php';

if (!class_exists('XSSHelpers'))
{
    include_once dirname(__FILE__) . '/../../../libs/php-commons/XSSHelpers.php';
}

/**
 * Purpose: Class to connect to VA's CDW databases (MSSQL)
 */
class CDWdataController extends RESTfulResponse
{
    public $index = array();

    private $API_VERSION = 1;    // Integer

    private $cdw;

    public function __construct($db, $login)
    {
        $this->cdw = new CDW($db, $login);
    }

    public function get($act)
    {
        $cdw = $this->cdw;

        $this->index['GET'] = new ControllerMap();
        $this->index['GET']->register('cdw/version', function () {
            return $this->API_VERSION;
        });

        /** Validate Vaccine Status in CDW - Expects Valid Email Address and Optional Pathway*/
        $this->index['GET']->register('cdw/vaccine/[text]/status', function ($args) use ($cdw) {
            return $cdw->getVaccineStatus($args[0]);
        });

        /** Check Compliance and Send Email to userID*/
        $this->index['GET']->register('cdw/vaccine/[text]/email', function ($args) use ($cdw) {
            return $cdw->vaccineStatusEmail($args[0]);
        });

        return $this->index['GET']->runControl($act['key'], $act['args']);
    }

    public function post($act)
    {
        $cdw = $this->cdw;

        $this->index['POST'] = new ControllerMap();
        $this->index['POST']->register('cdw', function ($args) {
        });

        /** Error Reporting for API Fail to CDW */
        $this->index['POST']->register('cdw/vaccine/error', function () use ($cdw) {
            return $cdw->vaccineInfoError($_POST['recordID'], $_POST['userID']);
        });

        /** Run bulk export of LEAF data to CDW */
        $this->index['POST']->register('cdw/vaccine/bulkexport', function () use ($cdw) {
            return $cdw->vaccineBulkExport();
        });

        /** Modify Vaccine when record ID unknown **/
        $this->index['POST']->register('cdw/vaccine/[digit]/submit', function ($args) use ($cdw) {
            return $cdw->modifyVaccine((int)$args[0]);
        });

        /** Modify Vaccine when record ID unknown **/
        $this->index['POST']->register('cdw/vaccine/[digit]/local/submit', function ($args) use ($cdw) {
            return $cdw->modifyLocalVaccine((int)$args[0]);
        });

        // Expected digit is LEAF Record ID to be removed from CDW Uploads
        $this->index['POST']->register('cdw/vaccine/[digit]/remove', function ($args) use ($cdw) {
            return $cdw->deleteVaccine((int)$args[0]);
        });

        // Expected digit is LEAF Record ID to be removed from CDW Uploads
        $this->index['POST']->register('cdw/vaccine/[digit]/local/remove', function ($args) use ($cdw) {
            return $cdw->deleteLocalVaccine((int)$args[0]);
        });

        return $this->index['POST']->runControl($act['key'], $act['args']);
    }
}
