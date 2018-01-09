import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { Well, Tab, Row, Col, Nav, NavItem } from 'react-bootstrap';

import { withUserConfig, UserConfigPropTypes, UserConfigKeys } from '../utils/userConfig';

import Status from '../components/dashboard/status';
import Gamification from '../components/dashboard/gamification';
let Online = require( '../components/dashboard/online.jsx' );
import { ReportDashboard } from '../components/dashboard/report';

const dashboardReports = ReportDashboard();

const NEWTABKEY = 'new';

class HomeDashboard extends PureComponent {
	constructor( props ) {
		super( props );

		this.state = {};

		this.switchTab = this.switchTab.bind(this);
		this.closeTab = this.closeTab.bind(this);
	}

	static propTypes = {
		loggedIn: PropTypes.bool.isRequired,
		sensitivity: PropTypes.string,
		...UserConfigPropTypes,
	}

	dashboardHeader = (
		<div className="home-grid">
			<div className="title-area">
				{ this.props.sensitivity && 
					<h2 className="sensitivity">{this.props.sensitivity}</h2>
				}
				<h3>Sandia Cyber Omni Tracker
					<br />
					3.5
				</h3>
			</div>
			<Status className="status-area" />
			<div className="game-area">
				<Gamification />
			</div>
			<Well bsSize="small" className="activity-area">
				Activity
			</Well>
		</div>
	);

	defaultTab() {
		return {
			title: 'Default',
			layout: dashboardReports,
			mountOnEnter: false,
			unmountOnExit: false,
		}
	}

	newTab() {
		const dashboardConfig = this.props.userConfig.config;
		let tabs = [...dashboardConfig.tabs];
		tabs.push( `Tab ${tabs.length + 1}` )

		this.updateDashboardConfig( {
			curTab: tabs.length,
			tabs: tabs,
		} );
	}

	buildTab( tabConfig ) {
		return {
			title: tabConfig,
			layout: <h1>{tabConfig}</h1>,
		}
	}

	closeTab( index ) {
		if ( index < 1 ) {
			return;
		}

		const dashboardConfig = this.props.userConfig.config;
		let tabs = [...dashboardConfig.tabs];
		tabs.splice( index - 1, 1 );

		this.updateDashboardConfig( {
			curTab: index - 1,
			tabs: tabs,
		} );
	}

	switchTab( key ) {
		if ( key === this.props.userConfig.config.curTab ) {
			return;
		}
		if ( key === NEWTABKEY ) {
			this.newTab();
			return;
		}

		this.updateDashboardConfig({
			curTab: key,
		} );
	}

	updateDashboardConfig( newConfig ) {
		const dashboardConfig = this.props.userConfig.config;

		this.props.userConfig.setUserConfig( {
			...dashboardConfig,
			...newConfig,
		} );
	}

	render() {
		if ( !this.props.loggedIn ) {
			return (
				<div className="homePageDisplay">
					<div className="home-grid loggedOut">
						<div className="title-area">
							<h1>Sandia Cyber Omni Tracker
								<br />
								3.5
							</h1>
						</div>
					</div>
				</div>
			)
		}

		const dashboardConfig = this.props.userConfig.config;
		const tabsConfig = dashboardConfig.tabs;
		
		let tabs = []
		tabs.push( this.defaultTab() );

		for ( let newTab of tabsConfig ) {
			tabs.push( this.buildTab( newTab ) );
		}

		let tabHeaders = tabs.map( (tab, i) => {
			let { title, layout, ...props } = tab;
			return (
				<NavItem eventKey={i} key={i}>
					{title}
					{ i === dashboardConfig.curTab && i !== 0 &&
							<span onClick={() => this.closeTab(i)}>&nbsp;<i className="fa fa-times" style={{cursor: "pointer"}} /></span>
					}
				</NavItem>
			)
		} );

		tabHeaders.push( <NavItem eventKey={NEWTABKEY} key={NEWTABKEY}>+</NavItem> );

		const tabContent = tabs.map( (tab, i) => {
			let { title, layout, ...props } = tab;
			return <Tab.Pane eventKey={i} key={i} {...props}>{layout}</Tab.Pane>
		} );



		return (
			<div className="homePageDisplay">
				<Tab.Container id="DashboardTabs" activeKey={dashboardConfig.curTab} onSelect={this.switchTab}>
					<Row>
						<Col sm={12}>
							<Nav bsStyle='tabs'>
								{tabHeaders}
							</Nav>
						</Col>
						<Col sm={12}>
							<Tab.Content mountOnEnter unmountOnExit >
								{this.dashboardHeader}
								{tabContent}
							</Tab.Content>
						</Col>
					</Row>
				</Tab.Container>
			</div>
		)
	}
}

export default withUserConfig( UserConfigKeys.DASHBOARD ) (HomeDashboard);
