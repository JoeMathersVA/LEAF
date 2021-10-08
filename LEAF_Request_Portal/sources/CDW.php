<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

/*
    CDW controls
    Date Created: October 5, 2021
*/

$currDir = dirname(__FILE__);

require_once $currDir . '/../globals.php';
require_once $currDir . '/../db_cdw_sqlsrv.php';
if (!class_exists('XSSHelpers')) {
    require_once dirname(__FILE__) . '/../../libs/php-commons/XSSHelpers.php';
}
if (!class_exists('Orgchart\Config'))
{
    require_once __DIR__ . '/' . Config::$orgchartPath . '/config.php';
    require_once __DIR__ . '/' . Config::$orgchartPath . '/sources/Login.php';
    require_once __DIR__ . '/' . Config::$orgchartPath . '/sources/Employee.php';
    require_once __DIR__ . '/' . Config::$orgchartPath . '/sources/NationalEmployee.php';
 }

class CDW
{
    public $siteRoot = '';

    private $db;
    private $db_nexus;
    private $db_nat;
    private $db_cdw;

    private $login;
    private $employee;
    private $nat_employee;

    private $dataActionLogger;

    public function __construct($db, $login)
    {
        $this->db = $db;
        $this->login = $login;
        // $this->db_cdw = new DB_CDW();

        $config = new Config();
        $this->db_nexus = new DB($config->phonedbHost, $config->phonedbUser, $config->phonedbPass, $config->phonedbName);
        $this->db_nat = new DB(DIRECTORY_HOST, DIRECTORY_USER, DIRECTORY_PASS, DIRECTORY_DB);
        $login_nat = new Login($this->db_nat, $this->db_nat);

        $this->employee = new Orgchart\Employee($this->db_nexus, $login);
        $this->nat_employee = new Orgchart\NationalEmployee($this->db_nat, $login_nat);

        $this->siteRoot = "https://" . HTTP_HOST . dirname($_SERVER['REQUEST_URI']) . '/';
    }

    public function getVaccineStatus($empEmail = null) {
        if ($empEmail === null) {
            return 'Invalid Email.';
        }
    }

    public function modifyVaccine($recordID = null) {

        $strVar = array(
            ':indicatorID' => array(242,261,42,262,48,195, 183, 187, 184, 188, 104, 265, 210, 282, 106)
        );
        $strSQL = 'SELECT rec.recordID, rec.userID, dt.data, dt.timestamp, indi.indicatorID, rec.submitted 
                FROM data AS dt
                    INNER JOIN indicators AS indi ON indi.indicatorID = data.indicatorID
                    INNER JOIN categories AS cate ON indi.categoryID = cate.categoryID
                    INNER JOIN records AS rec ON rec.recordID = data.recordID
                WHERE
                    cate.disabled = 0
                    AND indi.disabled = 0
                    AND rec.submitted > 0
                    AND dt.indicatorID IN :indicatorID
                    AND rec.deleted = 0';
        if ($recordID != null) {
            $strSQL .= ' AND rec.recordID = '.$recordID.' ';
        }
        $strSQL .= 'ORDER BY
                        recordID, indicatorID';

        $res = $this->db->prepared_query($strSQL, $strVar);

        $result = array();
        $newRecord = true;
        $packet = [];

        foreach ($res as $tmp) {
            // Add new record if recordID isn't in current packet & store previous packet
            if (($newRecord === false) && ($tmp['recordID'] !== $packet['vaccineInfoID'])) {
                $newRecord = true;
                $result[] = $packet;
            }
            // If new record is needed, build packet
            if ($newRecord === true) {
                $packet = array(
                    'vaccineInfoID' => $tmp['recordID'],
                    'submittedDate' => date("Y-m-d H:i:s",$tmp['submitted']),
                    'employeeEmail' => null,
                    'employeeAD' => null,
                    'supervisorEmail' => null,
                    'supervisorAD' => null,
                    'vaccinePathway' => null,
                    'vaccineName' => null,
                    'doseOneDate' => null,
                    'doseOneLocation' => null,
                    'doseTwoDate' => null,
                    'doseTwoLocation' => null,
                    'vaccineDocType' => null,
                    'exceptionType' => null,
                    'perjuryStatus' => 0,
                    'releaseStatus' => 0,
                    'vaccineDocDate' => null,
                    'lastModified' => null,
                    'dataUploadDT' => null
                );

                $tmpUserInfo = $this->nat_employee->lookupLogin($tmp['userID']);
                $vars = array(
                    ':empUID' => $tmpUserInfo[0]['empUID'],
                    ':email_indicator' => 6
                );
                $strSQL = 'SELECT data AS email FROM employee_data '.
                            'WHERE empUID=:empUID AND indicatorID=:email_indicator';
                $resUserEmail = $this->db_nat->prepared_query($strSQL, $vars);

                $tmpUserID = $tmpUserInfo[0]['userName'];
                $packet['employeeEmail'] = $resUserEmail[0]['email'];
                $packet['employeeAD'] = $tmpUserID;

                $vars = array(
                    ':recordID' => $tmp['recordID'],
                    ':forms' => array('form_2e22e', 'form_2e050', 'form_6958f'));
                $strSQL = "SELECT categoryID FROM category_count ".
                    "WHERE recordID = :recordID ".
                    "AND categoryID IN :forms";
                $resPath = $this->db->prepared_query($strSQL, $vars);

                if ($resPath[0]['categoryID'] === 'form_2e22e') {
                    $packet['vaccinePathway'] = 'Vaccinated by VHA - Import Records';
                } elseif ($resPath[0]['categoryID'] === 'form_2e050') {
                    $packet['vaccinePathway'] = 'Vaccinated by VHA/Outside - Manual Records';
                } elseif ($resPath[0]['categoryID'] === 'form_6958f') {
                    $packet['vaccinePathway'] = 'Exemption';
                }
                $newRecord = false;
            }

            $indicators = array(
                48  => 'Supervisor',
                104 => 'vaccineDocType',
                106 => 'vaccineDocDate', // datetime
                183 => 'doseOneDate',
                184 => 'doseTwoDate',
                187 => 'doseOneLocation',
                188 => 'doseTwoLocation',
                195 => 'vaccineName',
                210 => 'perjuryStatus', // not null = 1 else 0
                242 => 'releaseStatus', // not null = 1 else 0
                265 => 'exceptionType'
            );
            switch ($tmp['indicatorID']) {
                case 48:
                    $tmpLocalSuperInfo = $this->employee->lookupEmpUID($tmp['data']);
                    $tmpSuperInfo = $this->nat_employee->lookupLogin($tmpLocalSuperInfo[0]['userName']);
                    $vars = array(
                        ':empUID' => $tmpSuperInfo[0]['empUID'],
                        ':email_indicator' => 6
                    );
                    $strSQL = 'SELECT data AS email '.
                        'FROM employee_data WHERE empUID=:empUID AND indicatorID=:email_indicator';
                    $resSuperEmail = $this->db_nat->prepared_query($strSQL, $vars);
                    $tmpSuperID = $tmpSuperInfo[0]['userName'];
                    $packet['supervisorEmail'] = $resSuperEmail[0]['email'];
                    $packet['supervisorAD'] = $tmpSuperID;
                    break;
                case 104:
                case 183:
                case 184:
                case 187:
                case 188:
                case 195:
                case 265:
                    $packet[$tmp['indicatorID']] = $tmp['data'];
                    break;
                case 106:
                    $packet[$tmp['indicatorID']] = date("Y-m-d H:i:s",$tmp['timestamp']);
                    break;
                case 210:
                case 242:
                    if ($tmp['data'] !== null) {
                        $packet[$tmp['indicatorID']] = 1;
                    } else {
                        $packet[$tmp['indicatorID']] = 0;
                    }
                    break;
            }
        }
        $result[] = $packet;
        foreach ($result as $vaccine) {
            $vars = array(':vaccineInfoID' => $vaccine['vaccineInfoID'],
                ':employeeEmail' => $vaccine['employeeEmail'],
                ':employeeAD' => $vaccine['employeeAD'],
                ':supervisorEmail' => $vaccine['supervisorEmail'],
                ':supervisorAD' => $vaccine['supervisorAD'],
                ':vaccinePathway' => $vaccine['vaccinePathway'],
                ':vaccineName' => $vaccine['vaccineName'],
                ':doseOneDate' => $vaccine['doseOneDate'],
                ':doseOneLocation' => $vaccine['doseOneLocation'],
                ':doseTwoDate' => $vaccine['doseTwoDate'],
                ':doseTwoLocation' => $vaccine['doseTwoLocation'],
                ':vaccineDocType' => $vaccine['vaccineDocType'],
                ':exceptionType' => $vaccine['exceptionType'],
                ':perjuryStatus' => $vaccine['perjuryStatus'],
                ':releaseStatus' => $vaccine['releaseStatus'],
                ':vaccineDocDate' => $vaccine['vaccineDocDate'],
                ':submittedDate' => $vaccine['submittedDate']);
            $strSQL = 'REPLACE INTO vaccine_info (vaccineInfoID, employeeEmail, employeeAD, '.
                        'supervisorEmail, supervisorAD, vaccinePathway,vaccineName, doseOneDate, '.
                        'doseOneLocation, doseTwoDate, doseTwoLocation, vaccineDocType, exceptionType, '.
                        'perjuryStatus, releaseStatus, vaccineDocDate, submittedDate) '.
                        'VALUES (:vaccineInfoID, :employeeEmail, :employeeAD, '.
                            ':supervisorEmail, :supervisorAD, :vaccinePathway, :vaccineName, :doseOneDate, '.
                            ':doseOneLocation, :doseTwoDate, :doseTwoLocation, :vaccineDocType, :exceptionType, '.
                            ':perjuryStatus, :releaseStatus, :vaccineDocDate, :submittedDate)';
            $this->db->prepared_query($strSQL, $vars);
        }
    }

}
