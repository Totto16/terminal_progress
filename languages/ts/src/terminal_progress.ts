const ANSI_ESC: string = "\x1B"
const ANSI_OSC: string = ANSI_ESC + "]"

const ANSI_ST: string = ANSI_ESC + "\\"
const ANSI_BELL: string = "\x07"

const OSC_PROGRESS_REPORT_BASE: string = "9;4"

function toStringCapped(num: number): string {
	if (num < 0) {
		return (0).toFixed(0)
	}

	if (num > 100) {
		return (100).toFixed(0)
	}

	return num.toFixed(0)
}

function send_progress_impl(st: U8, pr: Optional<U8> = undefined): void {
	if (pr === undefined || pr === null) {
		process.stdout.write(
			ANSI_OSC +
				OSC_PROGRESS_REPORT_BASE +
				";" +
				st.toString() +
				ANSI_BELL
		)
	} else {
		process.stdout.write(
			ANSI_OSC +
				OSC_PROGRESS_REPORT_BASE +
				";" +
				st.toString() +
				";" +
				toStringCapped(pr) +
				ANSI_BELL
		)
	}
}

export type Optional<T> = T | undefined | null

export enum ProgressState {
	ProgressStateRemove = 0,
	ProgressStateSet = 1,
	ProgressStateError = 2,
	ProgressStateIndeterminate = 3,
	ProgressStatePaused = 4,
}

export type U8 = number

export interface ProgressReportRemove {
	type: ProgressState.ProgressStateRemove
}

export interface ProgressReportSet {
	type: ProgressState.ProgressStateSet
	value: U8
}

export interface ProgressReportError {
	type: ProgressState.ProgressStateError
	value: Optional<U8>
}

export interface ProgressReportIndeterminate {
	type: ProgressState.ProgressStateIndeterminate
}

export interface ProgressReportPaused {
	type: ProgressState.ProgressStatePaused
	value: Optional<U8>
}

export type ProgressReport =
	| ProgressReportRemove
	| ProgressReportSet
	| ProgressReportError
	| ProgressReportIndeterminate
	| ProgressReportPaused

export function send_progress(report: ProgressReport): void {
	if (!process.stdout.isTTY) {
		return
	}

	switch (report.type) {
		case ProgressState.ProgressStateRemove: {
			send_progress_impl(report.type)
			break
		}
		case ProgressState.ProgressStateSet: {
			send_progress_impl(report.type, report.value)
			break
		}
		case ProgressState.ProgressStateError: {
			send_progress_impl(report.type, report.value)
			break
		}
		case ProgressState.ProgressStateIndeterminate: {
			send_progress_impl(report.type)
			break
		}
		case ProgressState.ProgressStatePaused: {
			send_progress_impl(report.type, report.value)
			break
		}
		default: {
			return
		}
	}
}
