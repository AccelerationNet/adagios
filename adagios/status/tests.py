# -*- coding: utf-8 -*-
#
# Adagios is a web based Nagios configuration interface
#
# Copyright (C) 2014, Pall Sigurdsson <palli@opensource.is>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from django.utils import unittest
from django.test.client import Client
from django.utils.translation import ugettext as _

import pynag.Parsers
import os
from django.test.client import RequestFactory
from django.test import LiveServerTestCase
import adagios.status
import adagios.status.utils
import adagios.status.graphite
import adagios.settings
import adagios.utils


class LiveStatusTestCase(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.nagios_config = adagios.settings.nagios_config
        cls.environment = adagios.utils.FakeAdagiosEnvironment()
        cls.environment.create_minimal_environment()
        cls.environment.configure_livestatus()
        cls.environment.update_adagios_global_variables()
        cls.environment.start()
        cls.livestatus = cls.environment.get_livestatus()

        cls.factory = RequestFactory()

    @classmethod
    def tearDownClass(cls):
        cls.environment.terminate()

    def testLivestatusConnectivity(self):
        requests = self.livestatus.query('GET status', 'Columns: requests')
        self.assertEqual(
            1, len(requests), _("Could not get status.requests from livestatus"))

    def testLivestatusConfigured(self):
        config = pynag.Parsers.config(cfg_file=self.nagios_config)
        config.parse_maincfg()
        for k, v in config.maincfg_values:
            if k == "broker_module" and v.find('livestatus') > 1:
                tmp = v.split()
                self.assertFalse(
                    len(tmp) < 2, _(' We think livestatus is incorrectly configured. In nagios.cfg it looks like this: %s') % v)
                module_file = tmp[0]
                socket_file = tmp[1]
                self.assertTrue(
                    os.path.exists(module_file), _(' Livestatus Broker module not found at "%s". Is nagios correctly configured?') % module_file)
                self.assertTrue(
                    os.path.exists(socket_file), _(' Livestatus socket file was not found (%s). Make sure nagios is running and that livestatus module is loaded') % socket_file)
                return
        self.assertTrue(
            False, _('Nagios Broker module not found. Is livestatus installed and configured?'))

    def testPageLoad(self):
        """ Loads a bunch of status pages, looking for a crash """
        self.loadPage('/status/')
        self.loadPage('/status/hosts')
        self.loadPage('/status/services')
        self.loadPage('/status/contacts')
        self.loadPage('/status/parents')
        self.loadPage('/status/state_history')
        self.loadPage('/status/log')
        self.loadPage('/status/comments')
        self.loadPage('/status/downtimes')
        self.loadPage('/status/hostgroups')
        self.loadPage('/status/servicegroups')
        self.loadPage('/status/map')
        self.loadPage('/status/dashboard')

    def test_status_detail(self):
        """ Tests for /status/detail """
        tmp = self.loadPage('/status/detail?contact_name=nagiosadmin')
        self.assertTrue('nagiosadmin belongs to the following' in tmp.content)

        tmp = self.loadPage('/status/detail?host_name=ok_host')
        self.assertTrue('ok_host' in tmp.content)

        tmp = self.loadPage('/status/detail?host_name=ok_host&service_description=ok%20service%201')
        self.assertTrue('ok_host' in tmp.content)

        tmp = self.loadPage('/status/detail?contactgroup_name=admins')
        self.assertTrue('nagiosadmin' in tmp.content)


    def testStateHistory(self):
        request = self.factory.get('/status/state_history')
        adagios.status.views.state_history(request)

    def loadPage(self, url, expected_status_code=200):
        """ Load one specific page, and assert if return code is not 200 """
        c = Client()
        response = c.get(url)
        self.assertEqual(response.status_code, expected_status_code, _("Expected status code %(code)s for page %(url)s") % {'code': expected_status_code, 'url': url})
        return response

    def testSubmitCommand(self):
        """ Test adagios.rest.status.submit_check_results
        """
        c = Client()
        data = {}
        data['host_name'] = 'adagios test host'
        data['service_description'] = 'nonexistant'
        data['status_code'] = "0"
        data['plugin_output'] = 'test message'
        data['performance_data'] = ''
        response = c.post('/rest/status/json/submit_check_result', data=data)
        self.assertEqual(200, response.status_code)


class Graphite(unittest.TestCase):
    def test__get_graphite_url(self):
        """ Smoketest for  adagios.status.graphite._get_graphite_url() """
        base = "http://localhost/graphite"
        host = "localhost"
        service = "Ping"
        metric = "packetloss"
        from_ = "-1d"
        parameters = locals()
        parameters.pop('self', None)
        result = adagios.status.graphite._get_graphite_url(**parameters)
        self.assertTrue(result.startswith(base))
        self.assertTrue(host in result)
        self.assertTrue(service in result)
        self.assertTrue(metric in result)

    def test_get(self):
        """ Smoketest for adagios.status.graphite.get() """
        base = "http://localhost/graphite"
        host = "localhost"
        service = "Ping"
        metrics = ["packetloss", "rta"]
        units = [("test", "test", "-1d")]
        parameters = locals()
        parameters.pop('self', None)
        result = adagios.status.graphite.get(**parameters)
        self.assertTrue(result)
        self.assertTrue(len(result) == 1)
        self.assertTrue('rta' in result[0]['metrics'])
        self.assertTrue('packetloss' in result[0]['metrics'])


class SplinterTestCase(LiveServerTestCase):
    browser = None
    environment = None


    @classmethod
    def setUpClass(cls):
        super(SplinterTestCase, cls).setUpClass()

        if 'TEST_SPLINTER' not in os.environ:
            cls.enable = False
            return
        import splinter
        cls.enable = True
        cls.nagios_config = adagios.settings.nagios_config
        cls.environment = adagios.utils.FakeAdagiosEnvironment()
        cls.environment.create_minimal_environment()
        cls.environment.configure_livestatus()
        cls.environment.update_adagios_global_variables()
        cls.environment.start()
        cls.livestatus = cls.environment.get_livestatus()

        splinter_args = {}
        for key, value in os.environ.iteritems():
            if key.startswith("TEST_SPLINTER_") is False:
                continue
            key = key.replace("TEST_SPLINTER_", "").lower()
            splinter_args[key] = value

        if 'url' in splinter_args:
            splinter_args['driver_name'] = 'remote'

        cls.browser = splinter.Browser(**splinter_args)

    @classmethod
    def tearDownClass(cls):
        super(SplinterTestCase, cls).tearDownClass()
        if cls.enable:
            cls.browser.quit()
            cls.environment.terminate()


    def test_network_parents(self):
        """Status Overview, Network Parents should show an integer"""
        if not self.enable:
            return
        self.browser.visit(self.live_server_url + "/status")

        # Second link is Network Parents in overview
        self.assertEqual(self.browser.find_link_by_href(
            "/status/parents")[1].html.isdigit(), True)

    def test_services_select_all(self):
        """Loads services list and tries to select everything

        Flow:
            Load http://<url>/status/services
            Click select all
            Look for statustable rows
            Assert that all rows are checked"""

        if not self.enable:
            return

        self.browser.visit(self.live_server_url + "/status/services")

        self.browser.find_by_xpath("//input[@class='select_many']").first.click()
        self.browser.find_by_xpath("//a[@class='select_all']").first.click()

        # Get all statustable rows
        status_table_rows = self.browser.find_by_xpath(
            "//table[contains(@class, 'statustable')]"
        ).first.find_by_xpath("//tbody/tr[contains(@class, 'mainrow')]")

        # Sub-select non-selected
        for row in status_table_rows:
            self.assertTrue(row.has_class("row_selected"),
                            "Non selected row found after selecting all: " + \
                            row.text)

    def test_status_overview_top_alert_producers(self):
        """Check the top alert producers part of status overview"""
        if not self.enable:
            return

        self.browser.visit(self.live_server_url + "/status")

        top_alert_table_rows = self.browser.find_by_xpath(
            "//table[@id='top_alert_producers']/tbody/tr"
        )

        count = 0
        for row in top_alert_table_rows:
            if 'display' not in row['style']:
                count += 1

        self.assertTrue(count <= 3, "Top alert producers returns too many rows")
